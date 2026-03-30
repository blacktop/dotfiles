function gomod-update --description 'Update Go modules to latest versions excluding indirect dependencies'
    set -l mods (go list -f '{{if not (or .Main .Indirect)}}{{.Path}}{{end}}' -m all)
    if test (count $mods) -gt 0
        go get $mods
    end
end