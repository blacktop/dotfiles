function offline-updates-close --description 'Close PF offline update window immediately'
    sudo pfctl -a offline-updates -F rules
    and logger -t offline-updates "Update window closed manually"
    and echo "✓ Update window closed"
    or begin
        echo "✗ Failed to close update window" >&2
        return 1
    end
end
