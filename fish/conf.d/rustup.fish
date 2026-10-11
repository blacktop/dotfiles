# Prefer existing Rustup tools, with Homebrew's keg-only proxies as a fallback.
if type -q brew
    set -l rustup_bin (brew --prefix)/opt/rustup/bin
    if test -x "$rustup_bin/rustup"
        fish_add_path --move --path "$HOME/.cargo/bin" "$rustup_bin"
    end
end
