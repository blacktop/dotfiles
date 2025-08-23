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

    # Get input either from args or stdin
    set -l instruction
    if test (count $argv) -gt 0
        set instruction (string join ' ' -- $argv)
    else
        # Check if stdin has data
        if not isatty stdin
            # Read from stdin using read builtin
            read instruction
        end
    end

    # Ensure input is not empty
    if test -z "$instruction"
        echo "Usage: asm \"mov x1, #10\"  or  echo 'mov x1, #10' | asm" >&2
        return 2
    end

    # Run assembler with encoding output, capture both stdout and stderr
    set -l out (printf '%s\n' $instruction | $llvm_mc -arch=arm64 -mattr=v8.5a -show-encoding 2>&1)

    # Extract hex bytes from the encoding line - llvm-mc outputs format: [0x00,0x7c,0x00,0xb1]
    set -l bytes (printf '%s\n' $out | string match -r -a '0x[0-9a-fA-F]+')

    if test (count $bytes) -lt 4
        echo "asm: failed to parse encoding for: $instruction" >&2
        printf '%s\n' $out >&2
        return 1
    end

    # Output first four bytes in lowercase
    set -l bytes4 (string lower -- $bytes[1..4])
    echo (string join ' ' -- $bytes4)
end
