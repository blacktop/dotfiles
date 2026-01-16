function gh-secret-sync -d "Sync TAP_GITHUB_TOKEN secret to multiple repos"
    if not set -q TAP_GITHUB_TOKEN
        echo "Error: TAP_GITHUB_TOKEN is not set"
        return 1
    end

    set -l repos \
        blacktop/bottle-bomb \
        blacktop/clim8 \
        blacktop/fluxy \
        blacktop/go-foundationmodels \
        blacktop/go-gitfamous \
        blacktop/go-hypervisor \
        blacktop/mcp-tts \
        blacktop/xpost

    for repo in $repos
        echo "Updating $repo..."
        echo $TAP_GITHUB_TOKEN | gh secret set TAP_GITHUB_TOKEN --repo $repo
        and echo "  ✓ $repo"
        or echo "  ✗ $repo failed"
    end
end
