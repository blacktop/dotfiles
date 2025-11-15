function rust-release --description 'Bump version, generate changelog, tag, push, publish, and create a GitHub release'
    set -l changelog CHANGELOG.md
    if set -q RUST_RELEASE_CHANGELOG
        set changelog $RUST_RELEASE_CHANGELOG
    end
    set -l bump_mode patch
    set -l requested_version ''
    set -l crate_version ''
    set -l notes_file ''
    set -l dry_run 0

    # git-cliff config (default to `-c github`, overridable via env)
    set -l cliff_args -c github
    if set -q RUST_RELEASE_GIT_CLIFF_CONFIG
        set cliff_args -c $RUST_RELEASE_GIT_CLIFF_CONFIG
    end

    set -l mode_arg ''
    for arg in $argv
        switch $arg
            case '-h' '--help'
                printf 'Usage: rust-release [--dry-run] [patch|minor|major|<semver>]\n' >&2
                printf 'Bumps crate version, updates %s, tags, pushes, publishes to crates.io, and creates a GitHub release.\n' $changelog >&2
                return 0
            case '--dry-run'
                set dry_run 1
            case '*'
                if test -z "$mode_arg"
                    set mode_arg $arg
                else
                    printf 'Usage: rust-release [--dry-run] [patch|minor|major|<semver>]\n' >&2
                    return 64
                end
        end
    end

    if test -n "$mode_arg"
        if string match -rq -- '^(major|minor|patch)$' $mode_arg
            set bump_mode $mode_arg
        else if string match -rq -- '^v?[0-9]+\.[0-9]+\.[0-9]+([-.][0-9A-Za-z]+)?$' $mode_arg
            set requested_version (string replace -r '^v' '' -- $mode_arg)
        else
            printf 'Usage: rust-release [--dry-run] [patch|minor|major|<semver>]\n' >&2
            return 64
        end
    end

    if not command -sq cargo
        printf 'rust-release requires cargo on PATH.\n' >&2
        return 127
    end

    if not command -sq git
        printf 'rust-release requires git on PATH.\n' >&2
        return 127
    end

    if not command -sq jq
        printf 'rust-release requires jq on PATH (for parsing cargo metadata).\n' >&2
        return 127
    end

    if not command -sq git-cliff
        printf 'rust-release requires git-cliff on PATH (for changelog and release notes).\n' >&2
        return 127
    end

    if not command -sq cargo-set-version
        printf 'rust-release needs `cargo set-version` (install via `cargo install cargo-edit`).\n' >&2
        return 127
    end

    if not command -sq gh
        printf 'rust-release needs the GitHub CLI `gh` on PATH to create releases.\n' >&2
        return 127
    end

    set -l dirty_status (command git status --porcelain --untracked-files=normal)
    set -l git_status $status
    if test $git_status -ne 0
        printf 'rust-release must be run inside a git repository.\n' >&2
        return $git_status
    end
    if test (count $dirty_status) -ne 0
        printf 'Aborting release: working tree has uncommitted changes:\n' >&2
        printf '%s\n' $dirty_status >&2
        return 1
    end

    set -l manifest_path (command cargo locate-project --message-format plain)
    if test $status -ne 0
        printf 'Failed to locate Cargo.toml (are you in a Rust crate directory?).\n' >&2
        return $status
    end
    set -l manifest_dir (command dirname -- $manifest_path)
    set -l lock_path "$manifest_dir/Cargo.lock"

    set -l package_line (command cargo metadata --no-deps --format-version 1 --manifest-path $manifest_path \
        | command jq -r '.packages[0] | [.manifest_path, .version] | @tsv')
    if test $status -ne 0
        printf 'Failed to read cargo metadata.\n' >&2
        return $status
    end
    set -l parts (string split \t -- $package_line)
    set -l current_version $parts[2]
    set -l new_version $current_version

    if test -n "$requested_version"
        set new_version $requested_version
    else
        set -l base_and_suffix (string split -m 2 - -- $current_version)
        set -l base $base_and_suffix[1]
        set -l nums (string split . -- $base)
        if test (count $nums) -eq 3
            if string match -rq '^[0-9]+$' $nums[1]; and string match -rq '^[0-9]+$' $nums[2]; and string match -rq '^[0-9]+$' $nums[3]
                set -l major $nums[1]
                set -l minor $nums[2]
                set -l patch $nums[3]
                if test $bump_mode = 'major'
                    set -l new_major (math "$major + 1")
                    set new_version "$new_major.0.0"
                else if test $bump_mode = 'minor'
                    set -l new_minor (math "$minor + 1")
                    set new_version "$major.$new_minor.0"
                else
                    set -l new_patch (math "$patch + 1")
                    set new_version "$major.$minor.$new_patch"
                end
            end
        end
    end

    if test $dry_run -eq 1
        printf 'rust-release dry run:\n'
        printf '  crate manifest: %s\n' $manifest_path
        printf '  current version: %s\n' $current_version
        printf '  target version:  %s\n' $new_version
        printf '  changelog file:  %s\n' $changelog
        if test (count $cliff_args) -gt 0
            if set -q RUST_RELEASE_GIT_CLIFF_CONFIG
                set -l cliff_cfg $RUST_RELEASE_GIT_CLIFF_CONFIG
            else
                set -l cliff_cfg github
            end
            printf '  git-cliff config: %s\n' $cliff_cfg
        end
        printf '\nWould perform these steps:\n'
        if test -n "$requested_version"
            printf '  - cargo set-version --manifest-path %s %s\n' $manifest_path $requested_version
        else
            printf '  - cargo set-version --manifest-path %s --bump %s\n' $manifest_path $bump_mode
        end
        if test (count $cliff_args) -gt 0
            printf '  - git-cliff %s %s --unreleased --bump --prepend %s\n' $cliff_args[1] $cliff_args[2] $changelog
        else
            printf '  - git-cliff --unreleased --bump --prepend %s\n' $changelog
        end
        printf '  - git add %s and %s (and Cargo.lock if tracked)\n' $manifest_path $changelog
        printf '  - git commit -m "chore: release v%s"\n' $new_version
        printf '  - git tag v%s\n' $new_version
        printf '  - cargo publish --manifest-path %s\n' $manifest_path
        printf '  - git push && git push --tags\n'
        if test (count $cliff_args) -gt 0
            printf '  - git-cliff %s %s --latest | gh release create v%s ...\n' $cliff_args[1] $cliff_args[2] $new_version
        else
            printf '  - git-cliff --latest | gh release create v%s ...\n' $new_version
        end
        return 0
    end

    if test -n "$requested_version"
        command cargo set-version --manifest-path $manifest_path $requested_version; or return $status
    else
        command cargo set-version --manifest-path $manifest_path --bump $bump_mode; or return $status
    end

    command git-cliff $cliff_args --unreleased --bump --prepend $changelog; or return $status

    set -l package_line_after (command cargo metadata --no-deps --format-version 1 --manifest-path $manifest_path \
        | command jq -r '.packages[0] | [.manifest_path, .version] | @tsv')
    if test $status -ne 0
        printf 'Failed to read updated cargo metadata.\n' >&2
        return $status
    end

    set -l parts_after (string split \t -- $package_line_after)
    set crate_version $parts_after[2]

    command git add -- $manifest_path; or return $status
    if test -f $lock_path
        command git check-ignore -q -- $lock_path
        if test $status -ne 0
            command git add -- $lock_path; or return $status
        end
    end
    command git add -- $changelog; or return $status

    command git commit -m "chore: release v$crate_version"; or return $status
    command git tag "v$crate_version"; or return $status

    set -l post_commit_dirty (command git status --porcelain --untracked-files=normal)
    if test (count $post_commit_dirty) -ne 0
        printf 'Aborting release: working tree became dirty after release commit:\n' >&2
        printf '%s\n' $post_commit_dirty >&2
        return 1
    end

    command cargo publish --manifest-path $manifest_path; or return $status

    command git push; or return $status
    command git push --tags; or return $status

    set notes_file (mktemp -t rust-release.XXXXXX)
    if test $status -ne 0
        printf 'Failed to create temporary file for release notes.\n' >&2
        return 1
    end

    if not command git-cliff $cliff_args --latest > $notes_file
        set -l cliff_status $status
        command rm -f -- $notes_file
        return $cliff_status
    end

    command gh release create "v$crate_version" \
        --title "v$crate_version" \
        --notes-file $notes_file \
        --verify-tag
    set -l gh_status $status
    command rm -f -- $notes_file
    if test $gh_status -ne 0
        return $gh_status
    end

    printf 'Published crate version v%s and created GitHub release\n' $crate_version
end
