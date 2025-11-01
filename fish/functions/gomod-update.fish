function gomod-update --description 'Update Go modules to latest versions excluding indirect dependencies'
    go list -f '{{if not (or .Main .Indirect)}}{{.Path}}{{end}}' -m all | xargs --no-run-if-empty go get
end