function tort -d "Download all tortas"
    if test (count $argv) -ne 2
        echo "usage: tort MAGNET_LIST OUTPUT_DIR" >&2
        return 1
    end
    set -l magnets $argv[1]
    set -l outdir $argv[2]

    if not test -r "$magnets"
        echo "tort: cannot read magnet list: $magnets" >&2
        return 1
    end

    mkdir -p "$outdir"
    or return 1

    echo "killall transmission-cli" >/tmp/kill_me
    and chmod a+x /tmp/kill_me
    or return 1

    while read -l magnet
        test -n "$magnet"
        and transmission-cli -f /tmp/kill_me --verify --encryption-preferred -w "$outdir" "$magnet"
    end <"$magnets"
end
