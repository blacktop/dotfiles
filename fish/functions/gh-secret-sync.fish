function gh-secret-sync -d "Prompt for TAP_GITHUB_TOKEN and set it as a secret on each tap repo"
    # read keeps the token out of fish history, and --silent masks it as it is typed.
    set -l token
    read --silent --prompt-str "TAP_GITHUB_TOKEN: " token
    or return 1
    if test -z "$token"
        echo "gh-secret-sync: no token entered" >&2
        return 1
    end

    # Repos whose release workflows read secrets.TAP_GITHUB_TOKEN. Refresh with:
    # gh search code TAP_GITHUB_TOKEN --owner blacktop
    set -l repos \
        blacktop/arm64-cgo \
        blacktop/bottle-bomb \
        blacktop/ccpaths \
        blacktop/clim8 \
        blacktop/darwin-dyld-build \
        blacktop/disctui \
        blacktop/fluxy \
        blacktop/go-foundationmodels \
        blacktop/go-gitfamous \
        blacktop/go-hypervisor \
        blacktop/go-template \
        blacktop/headroom \
        blacktop/ipsw \
        blacktop/lifx \
        blacktop/mcp-tts \
        blacktop/rexurrect \
        blacktop/slack-tooy \
        blacktop/xpost

    for repo in $repos
        echo "Updating $repo..."
        printf '%s' $token | gh secret set TAP_GITHUB_TOKEN --repo $repo
        and echo "  ✓ $repo"
        or echo "  ✗ $repo failed"
    end
end
