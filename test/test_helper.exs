# Configure through the SAME code path the device uses, so a host test about
# configuration means something. Anything set only in config/config.exs is
# host-only by definition and never reaches a phone.
Kati.Runtime.configure()

ExUnit.start()
