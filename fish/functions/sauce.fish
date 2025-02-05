function sauce --description 'Check for Apple OSS distributions Updates'
    gh api graphql -F owner='apple-oss-distributions' -F name='distribution-macOS' -f query='
        query($owner: String!, $name: String!) {
        repository(owner: $owner, name: $name) {
            refs(
            refPrefix: "refs/tags/",
            first: 1,
            orderBy: { field: TAG_COMMIT_DATE, direction: DESC }
            ) {
            edges {
                node {
                name
                }
            }
            }
        }
        }
    ' --jq '.data.repository.refs.edges[0].node.name'
end