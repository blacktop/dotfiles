dotfiles
========

My personal .files

Mostly borrowed from https://dotfiles.github.io/

Developer-tool telemetry defaults to off. Full setup exports the opt-outs before
running installers and applies Go's persistent opt-out after installing Go.
To apply only the privacy defaults to an existing machine:

```fish
sh privacy/setup.sh
```

This disables Go's local collection and uploads, disables Homebrew analytics, and
installs Fish defaults for supported tools. Open a new shell afterward. See the
[covered tools and limits](privacy/README.md).
