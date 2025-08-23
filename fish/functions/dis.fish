function dis --description 'Disassemble AArch64 hex bytes to instruction(s) using llvm-mc'
    # Prefer Homebrew LLVM if present, otherwise fall back to PATH
    set -l llvm_mc /opt/homebrew/opt/llvm/bin/llvm-mc
    if not test -x $llvm_mc
        if type -q llvm-mc
            set llvm_mc (command -v llvm-mc)
        else
            echo "dis: llvm-mc not found at /opt/homebrew/opt/llvm/bin/llvm-mc and not in PATH" >&2
            echo "     Install LLVM (e.g.,: brew install llvm) or adjust the path in this function." >&2
            return 127
        end
    end

    # Get input either from args or stdin
    set -l hex_bytes
    if test (count $argv) -gt 0
        set hex_bytes (string join ' ' -- $argv)
    else
        # Check if stdin has data
        if not isatty stdin
            # Read from stdin using read builtin
            read hex_bytes
        end
    end

    # Ensure input is not empty
    if test -z "$hex_bytes"
        echo "Usage: dis \"0x41 0x01 0x80 0xd2\"  or  echo '0x41 0x01 0x80 0xd2' | dis" >&2
        return 2
    end

    # Normalize input to single spaces
    set -l normalized_bytes (string replace -r -a '\s+' ' ' -- $hex_bytes | string trim)

    # Run disassembler, suppress stderr
    set -l out (printf '%s\n' $normalized_bytes | $llvm_mc -disassemble -arch=arm64 -mattr=v8.5a 2>/dev/null)

    # Filter output: remove "--" separator lines and empty lines, strip comments
    set -l insns (printf '%s\n' $out | string match -v -- '--' | string match -v -r '^[[:space:]]*$' | string replace -r '([ \t]*;.*)$' '' | string trim)

    if test (count $insns) -eq 0
        echo "dis: failed to disassemble bytes: $normalized_bytes" >&2
        return 1
    end

    # Print instruction(s), one per line
    printf '%s\n' $insns
end
