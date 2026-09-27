#!/bin/sh
# Add/replace .deb packages in this apt repository and regenerate its index.
#
# Usage: update-index.sh <deb-file-or-directory> [...]
#
# For each .deb given (or found in a given directory), any existing deb
# in this repo for the same package name is removed, the new one is
# copied in, and the apt index (Packages, Packages.gz, Release,
# Release.gpg, InRelease) is regenerated and signed. The repo's .debs
# are gitignored -- only the regenerated index files get committed.
set -eu

cd "$(dirname "$0")"
REPO="$(pwd)"

if [ "$#" -eq 0 ]; then
	echo "Usage: $0 <deb-file-or-directory> [...]" >&2
	exit 1
fi

NEW_DEBS=""
for arg in "$@"; do
	if [ -d "$arg" ]; then
		for f in "$arg"/*.deb; do
			[ -e "$f" ] && NEW_DEBS="$NEW_DEBS $f"
		done
	elif [ -f "$arg" ]; then
		NEW_DEBS="$NEW_DEBS $arg"
	else
		echo "not found: $arg" >&2
		exit 1
	fi
done

if [ -z "$NEW_DEBS" ]; then
	echo "no .deb files found" >&2
	exit 1
fi

for deb in $NEW_DEBS; do
	pkg="$(basename "$deb" | sed -E 's/_[^_]+_[^_]+\.deb$//')"
	rm -f "$REPO/${pkg}"_*_*.deb
	cp "$deb" "$REPO/"
	echo "added $(basename "$deb")"
done

cd "$REPO"
apt-ftparchive packages . > Packages
gzip -k9f Packages
apt-ftparchive -c apt-ftparchive.conf release . > Release
rm -f Release.gpg InRelease
gpg --clearsign -o InRelease Release
gpg -abs -o Release.gpg Release

git add Packages Packages.gz Release Release.gpg InRelease
echo
echo "Index regenerated and staged. Review with 'git status'/'git diff --stat',"
echo "then commit and push:"
echo "  git commit -m 'Update apt index'"
echo "  git push"
