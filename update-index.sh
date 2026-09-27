#!/bin/sh
# Add/replace .deb packages in this apt repository and regenerate its index.
#
# Usage: update-index.sh [deb-file-or-directory] [...]
#
# For each .deb given (or found in a given directory), any existing deb
# in this repo for the same package name is removed, the new one is
# copied in, and the apt index (Packages, Packages.gz, Release,
# Release.gpg, InRelease) is regenerated and signed. The repo's .debs
# are gitignored -- only the regenerated index files get committed.
#
# Called with no arguments, it just regenerates the index over
# whatever's currently in the repo (including nothing at all -- an
# empty repo is a valid repo).
set -eu

# Signing key from the reubeninstitute-deb-signing-key package (installing
# it imports this key into root's keyring with ultimate trust).
KEYID=656717166D79B2E3C27C3EFF807CCC20F26CFF08

cd "$(dirname "$0")"
REPO="$(pwd)"

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
gpg --local-user "$KEYID" --clearsign -o InRelease Release
gpg --local-user "$KEYID" -abs -o Release.gpg Release

git add Packages Packages.gz Release Release.gpg InRelease
echo
echo "Index regenerated and staged. Review with 'git status'/'git diff --stat',"
echo "then commit and push:"
echo "  git commit -m 'Update apt index'"
echo "  git push"
