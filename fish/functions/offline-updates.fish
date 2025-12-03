function offline-updates --description 'Open PF offline update window for N seconds (default 900)'
    set -l duration 900
    if test (count $argv) -gt 0
        set duration $argv[1]
    end

    set -l pf_updates /etc/pf.offline-updates.conf
    if not test -f $pf_updates
        echo "✗ Missing $pf_updates" >&2
        echo "  Run: sudo ~/Developer/Mine/blacktop/dotfiles/offline/offline-firewall.sh enable" >&2
        return 1
    end

    # Validate syntax before loading
    if not sudo pfctl -nf $pf_updates 2>/dev/null
        echo "✗ Invalid pf rules syntax in $pf_updates" >&2
        return 1
    end

    sudo pfctl -a offline-updates -f $pf_updates
    or begin
        echo "✗ Failed to load update rules" >&2
        return 1
    end

    # Populate the tables with resolved IPs
    echo "Syncing update tables..."
    sudo /usr/local/bin/sync-pf-tables.sh
    or begin
        echo "⚠️  Warning: Failed to sync tables, update hosts may not be reachable" >&2
    end

    # Log to system log
    logger -t offline-updates "Update window opened for $duration seconds"

    if test $duration -gt 0
        # Use fish's background job handling
        sudo fish -c "sleep $duration; pfctl -a offline-updates -F rules; logger -t offline-updates 'Update window auto-closed after $duration seconds'" &
        set -l pid (jobs -lp | tail -n1)
        echo "✓ Update window opened for $duration seconds"
        echo "  Auto-close job PID: $pid"
        echo "  To close early: offline-updates-close"
        echo "  To cancel auto-close: kill $pid"
    else
        echo "✓ Update window opened (no auto-close)"
        echo "  Close with: offline-updates-close"
    end
end

function offline-updates-close --description 'Close PF offline update window immediately'
    sudo pfctl -a offline-updates -F rules
    and logger -t offline-updates "Update window closed manually"
    and echo "✓ Update window closed"
    or begin
        echo "✗ Failed to close update window" >&2
        return 1
    end
end

function offline-updates-status --description 'Check if offline update window is open'
    if sudo pfctl -a offline-updates -sr 2>/dev/null | grep -q .
        echo "✓ Update window is OPEN"
        echo ""
        echo "Active rules:"
        sudo pfctl -a offline-updates -sr
        return 0
    else
        echo "✗ Update window is CLOSED"
        return 1
    end
end
