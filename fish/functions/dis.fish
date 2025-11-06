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

    # Normalize input to single spaces first
    set -l normalized_bytes (string replace -r -a '\s+' ' ' -- $hex_bytes | string trim)

    # Detect format and normalize to "0xXX 0xXX" format
    # Format 1: "b5 0a 20 d9" (space-separated, no 0x)
    # Format 2: "0xb5 0x0a 0x20 0xd9" (space-separated with 0x)
    # Format 3: "b50a20d9" (continuous hex string)
    # Format 4: "0xb50a20d9" (continuous hex string with 0x prefix)

    if string match -q -r '^0x[0-9a-fA-F]+$' -- $normalized_bytes
        # Format 4: Single continuous hex string with 0x prefix
        # Remove 0x prefix and split into byte pairs
        set -l hex_only (string replace '0x' '' -- $normalized_bytes)
        set -l byte_pairs (string match -r -a '..' -- $hex_only)
        set normalized_bytes (string join ' ' -- (for byte in $byte_pairs; echo "0x$byte"; end))
    else if string match -q -r '^[0-9a-fA-F]+$' -- $normalized_bytes
        # Format 3: Single continuous hex string without 0x
        # Split into byte pairs and add 0x prefix
        set -l byte_pairs (string match -r -a '..' -- $normalized_bytes)
        set normalized_bytes (string join ' ' -- (for byte in $byte_pairs; echo "0x$byte"; end))
    else if not string match -q -r '^0x' -- $normalized_bytes
        # Format 1: Space-separated bytes without 0x prefix
        # Add 0x prefix to each byte
        set -l bytes (string split ' ' -- $normalized_bytes)
        set normalized_bytes (string join ' ' -- (for byte in $bytes; echo "0x$byte"; end))
    end
    # Format 2 already has correct format (0xXX 0xXX), no transformation needed

    # Run disassembler, suppress stderr
    set -l out (printf '%s\n' $normalized_bytes | $llvm_mc -disassemble -arch=arm64 -mattr=v9.6a --mattr=mte 2>/dev/null)

    # Filter output: remove "--" separator lines and empty lines, strip comments
    set -l insns (printf '%s\n' $out | string match -v -- '--' | string match -v -r '^[[:space:]]*$' | string replace -r '([ \t]*;.*)$' '' | string trim)

    if test (count $insns) -eq 0
        echo "dis: failed to disassemble bytes: $normalized_bytes" >&2
        return 1
    end

    # Print instruction(s), one per line
    printf '%s\n' $insns
end
