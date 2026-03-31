#!/bin/sh
# Git SSH signing wrapper that sets the Secure Enclave provider.
# GUI apps (GitHub Desktop, Zed, etc.) don't inherit shell env vars,
# so git's signing subprocess needs this to find the SEP.
export SSH_SK_PROVIDER=/usr/lib/ssh-keychain.dylib
exec ssh-keygen "$@"
