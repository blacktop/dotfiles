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
