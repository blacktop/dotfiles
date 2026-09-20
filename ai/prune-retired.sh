#!/bin/sh
# Remove files from an installed profile that this repository used to install and
# has since deleted. A file goes only when its path is in Git's deletion history and
# its content is a version this repository shipped, so a file the user or a CLI
# created, or put back at a retired path, is never touched.
# Usage: prune-retired.sh <repository source directory> <installed profile directory>
set -eu
source_dir=$1
destination=$2
[ -d "$destination" ] || exit 0
repo=$(git -C "$source_dir" rev-parse --show-toplevel)
prefix=$(git -C "$source_dir" rev-parse --show-prefix)
real_destination=$(CDPATH='' cd -- "$destination" && pwd -P)

# Report whether the installed file matches any committed version of the path.
shipped() {
	installed_blob=$(git -C "$repo" hash-object -- "$2")
	git -C "$repo" log --format=%H --diff-filter=AM -- "$1" | while IFS= read -r commit; do
		[ "$(git -C "$repo" rev-parse "$commit:$1")" != "$installed_blob" ] || echo match
	done | grep -q match
}

{
	git -C "$repo" -c core.quotePath=false log --diff-filter=D --name-only --format= -- "$prefix"
	git -C "$repo" -c core.quotePath=false ls-files --deleted -- "$prefix"
} | sort -u | while IFS= read -r path; do
	[ -n "$path" ] || continue
	# A path that exists again was restored, not retired.
	[ ! -e "$repo/$path" ] || continue
	target="$destination/${path#"$prefix"}"
	[ -f "$target" ] && [ ! -L "$target" ] || continue
	# skills/ is a symlink to the shared skill directory; never follow one out.
	parent=$(CDPATH='' cd -- "$(dirname "$target")" && pwd -P)
	case "$parent/" in
	"$real_destination"/*) ;;
	*) continue ;;
	esac
	if ! shipped "$path" "$target"; then
		printf 'Kept %s: it differs from every version this repository shipped\n' "$target"
		continue
	fi
	if command -v trash >/dev/null 2>&1; then
		trash "$target"
	else
		rm -f "$target"
	fi
	printf 'Removed retired %s\n' "$target"
done
