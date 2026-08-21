/*
 * c_src/kati_jni.h — the JNI glue Kati's project-owned static NIFs share.
 *
 * WHY THIS FILE EXISTS
 *
 * Mob's NIF table (deps/mob/src/mob_nif.erl + deps/mob/android/jni/mob_nif.zig)
 * lives inside the hex package, so Kati cannot add an entry to it without
 * forking the dependency. Everything Kati added to MobBridge.kt — the
 * credential store, the file transport, the notification arming, the periodic
 * worker — is therefore unreachable from Elixir until a *project-owned* NIF
 * binds it. `mix mob.add_nif <name> --type c` is mob_dev's supported route for
 * exactly that, and this header is the part every such NIF needs.
 *
 * THE ONE THING THAT IS NOT OBVIOUS: FindClass
 *
 * `FindClass` resolves against the class loader of the topmost Java frame on
 * the calling thread. A NIF runs on an Erlang scheduler thread, which was
 * created by ERTS and has no Java frames at all, so `FindClass` there falls
 * back to the *system* class loader and cannot see `com.example.kati.MobBridge`
 * — it returns NULL with a pending ClassNotFoundException, and the failure
 * looks like "the bridge method is missing" rather than "the lookup was done
 * from the wrong thread". Mob hits the same wall and answers it by caching the
 * jclass in `JNI_OnLoad` (mob_nif.zig:1712, `_mob_ui_cache_class_impl`), where
 * there IS a Java frame; its cache is a Zig-internal with no C linkage, so Kati
 * caches its own next to it. See the `K-21 nif-bridge-class` fence in
 * android/app/src/main/jni/beam_jni.c.
 *
 * THE WIRE CONTRACT
 *
 * Every bridge method Kati calls through here is `@JvmStatic`, takes and
 * returns `String`, and never throws across the boundary — replies are
 * "ok" / "ok:<payload>" / "error:<reason>", which the Elixir side maps through
 * a closed set of atoms. Values that are bytes rather than text cross
 * base64-encoded, because a JNI string is UTF-16 and a credential (or a file
 * path from a locale Kati did not anticipate) is not required to be valid text.
 *
 * ON A NON-ANDROID BUILD
 *
 * Every NIF that includes this compiles to a body answering
 * "error:no_native_store" / "error:no_bridge" outside `#ifdef __ANDROID__`.
 *
 * Nothing compiles that arm today: both NIFs are `archs: [:android]` in
 * mob.exs, because `mix mob.add_nif --type c` wires this directory's sources
 * into the Android build only and an iOS table entry would be an undefined symbol at
 * link time. The arm exists so that widening `archs` later is a config change
 * plus the iOS build wiring rather than a rewrite — and because the CMake
 * fallback path GLOBs every .c in this directory regardless of what mob.exs says.
 */

#ifndef KATI_JNI_H
#define KATI_JNI_H

#include <erl_nif.h>
#include <string.h>

/* ── Erlang-side helpers, both platforms ─────────────────────────────────── */

/* A fresh binary term holding `len` bytes of `s`. */
static inline ERL_NIF_TERM kati_binary(ErlNifEnv *env, const char *s, size_t len) {
    ERL_NIF_TERM term;
    unsigned char *buf = enif_make_new_binary(env, len, &term);
    if (buf == NULL) return enif_make_atom(env, "error");
    if (len > 0) memcpy(buf, s, len);
    return term;
}

/* A fresh binary term holding a NUL-terminated C string. */
static inline ERL_NIF_TERM kati_cstr_binary(ErlNifEnv *env, const char *s) {
    return kati_binary(env, s, strlen(s));
}

/*
 * Copy a binary argument into a NUL-terminated buffer the caller frees with
 * `enif_free`. Returns NULL when the term is not a binary — the caller turns
 * that into `badarg` rather than passing a garbage pointer to JNI.
 */
static inline char *kati_take_cstr(ErlNifEnv *env, ERL_NIF_TERM term) {
    ErlNifBinary bin;
    char *out;

    if (!enif_inspect_binary(env, term, &bin)) return NULL;
    out = (char *)enif_alloc(bin.size + 1);
    if (out == NULL) return NULL;
    if (bin.size > 0) memcpy(out, bin.data, bin.size);
    out[bin.size] = 0;
    return out;
}

static inline void kati_free_cstr(char *s) {
    if (s != NULL) enif_free(s);
}

#ifdef __ANDROID__

#include <jni.h>

/* Both published by android/app/src/main/jni/beam_jni.c. `g_jvm` is upstream's
 * (set in JNI_OnLoad); `g_kati_bridge_cls` is Kati's, cached in the same
 * function under the `K-21 nif-bridge-class` fence. */
extern JavaVM *g_jvm;
extern jclass g_kati_bridge_cls;

/*
 * A JNIEnv for the current thread, attaching it if ERTS created it (which it
 * did — every scheduler thread). `*attached` is set when this call did the
 * attaching, so the caller can detach and leave the thread as it found it;
 * this mirrors mob_nif.zig's `get_jenv`/`detachIfAttached` pair rather than
 * inventing a second lifecycle for the same threads.
 */
static inline JNIEnv *kati_jni_env(int *attached) {
    JNIEnv *env = NULL;

    *attached = 0;
    if (g_jvm == NULL) return NULL;

    if ((*g_jvm)->GetEnv(g_jvm, (void **)&env, JNI_VERSION_1_6) == JNI_OK) return env;
    if ((*g_jvm)->AttachCurrentThread(g_jvm, &env, NULL) != JNI_OK) return NULL;

    *attached = 1;
    return env;
}

static inline void kati_jni_release(int attached) {
    if (attached && g_jvm != NULL) (*g_jvm)->DetachCurrentThread(g_jvm);
}

/*
 * Clear any pending Java exception and say whether there was one.
 *
 * A pending exception makes the *next* JNI call on this thread abort the
 * process, so leaving one in place turns "one bridge call failed" into "the app
 * died several unrelated calls later". Every call site clears before returning.
 */
static inline int kati_jni_failed(JNIEnv *env) {
    if ((*env)->ExceptionCheck(env)) {
        (*env)->ExceptionDescribe(env);
        (*env)->ExceptionClear(env);
        return 1;
    }
    return 0;
}

/* A Java String from a C string, or NULL for a NULL input (which JNI accepts
 * as a null argument). */
static inline jstring kati_jstring(JNIEnv *env, const char *s) {
    if (s == NULL) return NULL;
    return (*env)->NewStringUTF(env, s);
}

/*
 * Copy a returned Java String into an Erlang binary and release it.
 * A null return becomes the sentinel `fallback`, so a bridge method that
 * somehow answers null cannot be mistaken for a successful empty reply.
 */
static inline ERL_NIF_TERM kati_take_jstring(ErlNifEnv *env, JNIEnv *jenv, jstring value,
                                             const char *fallback) {
    const char *chars;
    ERL_NIF_TERM term;

    if (value == NULL) return kati_cstr_binary(env, fallback);

    chars = (*jenv)->GetStringUTFChars(jenv, value, NULL);
    if (chars == NULL) {
        (*jenv)->DeleteLocalRef(jenv, value);
        return kati_cstr_binary(env, fallback);
    }

    term = kati_cstr_binary(env, chars);
    (*jenv)->ReleaseStringUTFChars(jenv, value, chars);
    (*jenv)->DeleteLocalRef(jenv, value);
    return term;
}

/*
 * Call `MobBridge.<method>(a1, a2)` — either argument may be NULL to shorten
 * the signature — and return its String reply as an Erlang binary.
 *
 * `sig` is the JNI descriptor, passed rather than derived so a mismatch is a
 * compile-time-visible literal at the call site instead of a silent
 * GetStaticMethodID failure. Every failure answers `error:<something>` rather
 * than raising, because these are called from the single screen process and a
 * raise there is a black screen.
 */
static inline ERL_NIF_TERM kati_bridge_call(ErlNifEnv *env, const char *method, const char *sig,
                                            const char *a1, const char *a2) {
    int attached = 0;
    JNIEnv *jenv;
    jmethodID mid;
    jstring j1 = NULL;
    jstring j2 = NULL;
    jstring reply;
    ERL_NIF_TERM term;

    jenv = kati_jni_env(&attached);
    if (jenv == NULL) return kati_cstr_binary(env, "error:no_jvm");

    if (g_kati_bridge_cls == NULL) {
        kati_jni_release(attached);
        return kati_cstr_binary(env, "error:no_bridge");
    }

    mid = (*jenv)->GetStaticMethodID(jenv, g_kati_bridge_cls, method, sig);
    if (mid == NULL || kati_jni_failed(jenv)) {
        kati_jni_release(attached);
        return kati_cstr_binary(env, "error:no_method");
    }

    if (a1 != NULL) j1 = kati_jstring(jenv, a1);
    if (a2 != NULL) j2 = kati_jstring(jenv, a2);

    if (a1 != NULL && j1 == NULL) {
        if (j2 != NULL) (*jenv)->DeleteLocalRef(jenv, j2);
        kati_jni_failed(jenv);
        kati_jni_release(attached);
        return kati_cstr_binary(env, "error:jni_oom");
    }
    if (a2 != NULL && j2 == NULL) {
        if (j1 != NULL) (*jenv)->DeleteLocalRef(jenv, j1);
        kati_jni_failed(jenv);
        kati_jni_release(attached);
        return kati_cstr_binary(env, "error:jni_oom");
    }

    if (a2 != NULL) {
        reply = (jstring)(*jenv)->CallStaticObjectMethod(jenv, g_kati_bridge_cls, mid, j1, j2);
    } else if (a1 != NULL) {
        reply = (jstring)(*jenv)->CallStaticObjectMethod(jenv, g_kati_bridge_cls, mid, j1);
    } else {
        reply = (jstring)(*jenv)->CallStaticObjectMethod(jenv, g_kati_bridge_cls, mid);
    }

    if (kati_jni_failed(jenv)) {
        if (reply != NULL) (*jenv)->DeleteLocalRef(jenv, reply);
        reply = NULL;
        term = kati_cstr_binary(env, "error:threw");
    } else {
        term = kati_take_jstring(env, jenv, reply, "error:null_reply");
    }

    if (j1 != NULL) (*jenv)->DeleteLocalRef(jenv, j1);
    if (j2 != NULL) (*jenv)->DeleteLocalRef(jenv, j2);
    kati_jni_release(attached);
    return term;
}

/*
 * Call `MobBridge.<method>(long pid, String arg)` — the shape mob uses for
 * every asynchronous capability (mob_nif.zig's `callBridgePidStr`). The result
 * arrives later as an Erlang message through one of the `mob_deliver_*` hooks,
 * so this returns only whether the *call* got through.
 *
 * The pid is packed into a jlong exactly the way mob packs it, so the value
 * Kotlin hands back to `nativeDeliverFileResult` round-trips through mob's own
 * `pidFromLong`. ERL_NIF_TERM is 64-bit on both ABIs Kati ships (arm64-v8a and
 * x86_64 — see `K-01 abi-filters`), so this is a plain widening; the 32-bit
 * truncation dance in mob's helper has no case to cover here.
 */
static inline ERL_NIF_TERM kati_bridge_call_pid(ErlNifEnv *env, const char *method,
                                                const char *sig, const char *arg) {
    int attached = 0;
    JNIEnv *jenv;
    jmethodID mid;
    jstring jarg = NULL;
    ErlNifPid pid;
    jlong jpid = 0;

    if (!enif_self(env, &pid)) return kati_cstr_binary(env, "error:no_pid");

    jenv = kati_jni_env(&attached);
    if (jenv == NULL) return kati_cstr_binary(env, "error:no_jvm");

    if (g_kati_bridge_cls == NULL) {
        kati_jni_release(attached);
        return kati_cstr_binary(env, "error:no_bridge");
    }

    mid = (*jenv)->GetStaticMethodID(jenv, g_kati_bridge_cls, method, sig);
    if (mid == NULL || kati_jni_failed(jenv)) {
        kati_jni_release(attached);
        return kati_cstr_binary(env, "error:no_method");
    }

    if (arg != NULL) {
        jarg = kati_jstring(jenv, arg);
        if (jarg == NULL) {
            kati_jni_failed(jenv);
            kati_jni_release(attached);
            return kati_cstr_binary(env, "error:jni_oom");
        }
    }

    memcpy(&jpid, &pid, sizeof(jpid) < sizeof(pid) ? sizeof(jpid) : sizeof(pid));
    (*jenv)->CallStaticVoidMethod(jenv, g_kati_bridge_cls, mid, jpid, jarg);

    if (jarg != NULL) (*jenv)->DeleteLocalRef(jenv, jarg);

    if (kati_jni_failed(jenv)) {
        kati_jni_release(attached);
        return kati_cstr_binary(env, "error:threw");
    }

    kati_jni_release(attached);
    return kati_cstr_binary(env, "ok");
}

#endif /* __ANDROID__ */

#endif /* KATI_JNI_H */
