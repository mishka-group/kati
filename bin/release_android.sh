#!/usr/bin/env bash
# Builds the Android release exactly as .github/workflows/release.yml does,
# signed with the key in ~/.config/kati, and checks every file is signed.
#
#   bin/release_android.sh             # dist/kati_<version>_android_*.apk + .aab
#
# The key never enters the repository: android/keystore.properties is a
# symlink to ~/.config/kati/keystore.properties for the length of the build.
set -euo pipefail
cd "$(dirname "$0")/.."

PROPS="${KATI_KEYSTORE_PROPERTIES:-$HOME/.config/kati/keystore.properties}"
SDK="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
APKSIGNER="$(ls "$SDK"/build-tools/*/apksigner | tail -1)"
export MIX_ENV=dev

[ -f "$PROPS" ] || { echo "no keystore properties at $PROPS"; exit 1; }
[ -e android/keystore.properties ] && { echo "android/keystore.properties already exists; move it away first"; exit 1; }
ln -s "$PROPS" android/keystore.properties
trap 'rm -f android/keystore.properties' EXIT

version="$(sed -n 's/^  @version "\(.*\)"$/\1/p' mix.exs | head -1)"
echo "── Kati $version"

mix kati.version

# The same runtimes CI uses, handed to Gradle through the env fallback so
# android/local.properties is left alone. AppleDouble files are dropped for
# the same reason as in CI: beam_lib:strip_release stops at the first one.
export MOB_ANDROID_OTP_RELEASE MOB_ANDROID_OTP_RELEASE_ARM32 MOB_ANDROID_OTP_RELEASE_X86_64 MOB_DIR
eval "$(mix run --no-start -e '
  for {abi, var} <- [{"arm64-v8a", "MOB_ANDROID_OTP_RELEASE"},
                     {"armeabi-v7a", "MOB_ANDROID_OTP_RELEASE_ARM32"},
                     {"x86_64", "MOB_ANDROID_OTP_RELEASE_X86_64"}] do
    {:ok, path} = MobDev.OtpDownloader.ensure_android(abi)
    IO.puts("#{var}=#{path}")
  end')"
MOB_DIR="$PWD/deps/mob"
find "$HOME/.mob/cache" -name '._*' -delete
# The runtime tarballs carry an old exqlite beside the locked one, and
# mob_beam links sqlite3_nif.so into whichever lib/exqlite-* it reads first:
# the wrong one leaves the database unopenable and the app blank.
exqlite="$(mix run --no-start -e 'IO.puts MobDev.AppFile.dep_version(:exqlite)')"
find "$HOME"/.mob/cache/otp-android* -maxdepth 2 -type d -name 'exqlite-*' ! -name "exqlite-$exqlite" -print -exec rm -rf {} +

echo "── native"
mix run --no-start -e 'MobDev.NativeBuild.build_all(platforms: [:android])' || true

echo "── AAB"
mix mob.release --android

echo "── split APKs"
(cd android && ./gradlew assembleRelease --no-daemon -q -PsplitAbi)

out=android/app/build/outputs/apk/release
rm -rf dist && mkdir -p dist
for abi in arm64-v8a armeabi-v7a universal; do
  cp "$out/app-$abi-release.apk" "dist/kati_${version}_android_$abi.apk"
done
cp android/app/build/outputs/bundle/release/app-release.aab "dist/kati_${version}_android.aab"

echo "── signatures"
for apk in dist/*.apk; do
  "$APKSIGNER" verify "$apk" 2>/dev/null || { echo "NOT SIGNED: $apk"; exit 1; }
  echo "signed: $apk"
done
jarsigner -verify dist/*.aab >/dev/null || { echo "NOT SIGNED: AAB"; exit 1; }
echo "signed: dist/kati_${version}_android.aab"
ls -la dist
