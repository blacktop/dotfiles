function asm --description 'Assemble AArch64 instruction to hex bytes using llvm-mc'
    # Prefer Homebrew LLVM if present, otherwise fall back to PATH
    set -l llvm_mc /opt/homebrew/opt/llvm/bin/llvm-mc
    if not test -x $llvm_mc
        if type -q llvm-mc
            set llvm_mc (command -v llvm-mc)
        else
            echo "asm: llvm-mc not found at /opt/homebrew/opt/llvm/bin/llvm-mc and not in PATH" >&2
            echo "     Install LLVM (e.g.,: brew install llvm) or adjust the path in this function." >&2
            return 127
        end
    end

    # Parse format option
    set -l format '0x-space' # default: "0xb5 0x0a 0x20 0xd9"
    set -l instruction_args

    for arg in $argv
        switch $arg
            case '-f' '--format'
                # Next arg will be the format type
                continue
            case 'space' 'no0x'
                # Format 1: "b5 0a 20 d9"
                set format 'space'
            case '0x-space' '0x'
                # Format 2: "0xb5 0x0a 0x20 0xd9"
                set format '0x-space'
            case 'compact' 'continuous'
                # Format 3: "b50a20d9"
                set format 'compact'
            case '0x-compact' '0xcompact'
                # Format 4: "0xb50a20d9"
                set format '0x-compact'
            case '*'
                set -a instruction_args $arg
        end
    end

    # Get input either from remaining args or stdin
    set -l instruction
    if test (count $instruction_args) -gt 0
        set instruction (string join ' ' -- $instruction_args)
    else
        # Check if stdin has data
        if not isatty stdin
            # Read from stdin using read builtin
            read instruction
        end
    end

    # Ensure input is not empty
    if test -z "$instruction"
        echo "Usage: asm [-f FORMAT] \"mov x1, #10\"  or  echo 'mov x1, #10' | asm" >&2
        echo "Formats: space (b5 0a 20 d9), 0x-space (0xb5 0x0a...), compact (b50a20d9), 0x-compact (0xb50a20d9)" >&2
        return 2
    end

    # Run assembler with encoding output, capture both stdout and stderr
    set -l out (printf '%s\n' $instruction | $llvm_mc -arch=arm64 -mattr=v9.6a --mattr=mte -show-encoding 2>&1)

    # Extract hex bytes from the encoding line - llvm-mc outputs format: [0x00,0x7c,0x00,0xb1]
    set -l bytes (printf '%s\n' $out | string match -r -a '0x[0-9a-fA-F]+')

    if test (count $bytes) -lt 4
        echo "asm: failed to parse encoding for: $instruction" >&2
        printf '%s\n' $out >&2
        return 1
    end

    # Output first four bytes in lowercase, format according to user preference
    set -l bytes4 (string lower -- $bytes[1..4])

    switch $format
        case 'space'
            # Format 1: "b5 0a 20 d9" (no 0x prefix)
            set -l clean_bytes (string replace -r '^0x' '' -- $bytes4)
            echo (string join ' ' -- $clean_bytes)
        case '0x-space'
            # Format 2: "0xb5 0x0a 0x20 0xd9" (with 0x prefix, space-separated)
            echo (string join ' ' -- $bytes4)
        case 'compact'
            # Format 3: "9ad9640a" (little-endian word, no 0x)
            set -l clean_bytes (string replace -r '^0x' '' -- $bytes4)
            # Reverse byte order for little-endian 32-bit word
            echo (string join '' -- $clean_bytes[4] $clean_bytes[3] $clean_bytes[2] $clean_bytes[1])
        case '0x-compact'
            # Format 4: "0x9ad9640a" (little-endian word with 0x prefix)
            set -l clean_bytes (string replace -r '^0x' '' -- $bytes4)
            # Reverse byte order for little-endian 32-bit word
            echo "0x"(string join '' -- $clean_bytes[4] $clean_bytes[3] $clean_bytes[2] $clean_bytes[1])
    end
end
