function postgres --description 'Manually start PostgreSQL'
    set -l pg_dir (ls -d /opt/homebrew/opt/postgresql@* 2>/dev/null | sort -V | tail -n1)
    if test -z "$pg_dir"
        echo "postgres: no PostgreSQL installation found in /opt/homebrew/opt/" >&2
        return 127
    end
    LC_ALL=en_US.UTF-8 $pg_dir/bin/postgres -D /opt/homebrew/var/(path basename $pg_dir)
end
