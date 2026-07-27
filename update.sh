#!/usr/bin/env bash
# Bump PKGBUILD/.SRCINFO to the latest TIANLI0/THRM release.
# Exit 0 if already up to date (or after a successful bump).
set -euo pipefail

cd "$(dirname "$0")"

api="${GITHUB_API_URL:-https://api.github.com}/repos/TIANLI0/THRM/releases/latest"
tag=$(curl -fsSL "$api" | jq -r '.tag_name')
[[ -n "$tag" && "$tag" != null ]] || { echo "failed to resolve latest tag" >&2; exit 1; }
ver="${tag#v}"
ver="${ver#V}"

cur=$(sed -n 's/^pkgver=//p' PKGBUILD | head -1)
if [[ "$ver" == "$cur" ]]; then
  echo "already at $ver"
  exit 0
fi

echo "bumping $cur -> $ver"

tar_url="https://github.com/TIANLI0/THRM/releases/download/v${ver}/THRM-linux-amd64-portable.tar.gz"
lic_url="https://raw.githubusercontent.com/TIANLI0/THRM/v${ver}/LICENSE"
tar_sum=$(curl -fsSL "$tar_url" | sha256sum | awk '{print $1}')
lic_sum=$(curl -fsSL "$lic_url" | sha256sum | awk '{print $1}')

# Rewrite version + checksums in place.
awk -v ver="$ver" -v tar_sum="$tar_sum" -v lic_sum="$lic_sum" '
  /^pkgver=/ { print "pkgver=" ver; next }
  /^pkgrel=/ { print "pkgrel=1"; next }
  /^sha256sums=/,/^)/ {
    if (/^sha256sums=/) {
      print "sha256sums=("
      print "  '\''" tar_sum "'\''"
      print "  '\''" lic_sum "'\''"
      print ")"
      skip = 1
      next
    }
    if (skip && /^)/) { skip = 0; next }
    if (skip) next
  }
  { print }
' PKGBUILD > PKGBUILD.tmp
mv PKGBUILD.tmp PKGBUILD

# Keep .SRCINFO in sync without requiring makepkg (CI runs on Ubuntu).
cat > .SRCINFO <<EOF
pkgbase = thrm-bin
	pkgdesc = Flydigi BS-series laptop cooler controller (prebuilt)
	pkgver = ${ver}
	pkgrel = 1
	url = https://github.com/TIANLI0/THRM
	arch = x86_64
	license = MIT
	depends = gtk3
	depends = webkit2gtk-4.1
	depends = hidapi
	optdepends = bluez: BS1 BLE support
	provides = thrm
	conflicts = thrm
	options = !strip
	options = !debug
	source = https://github.com/TIANLI0/THRM/releases/download/v${ver}/THRM-linux-amd64-portable.tar.gz
	source = LICENSE::https://raw.githubusercontent.com/TIANLI0/THRM/v${ver}/LICENSE
	sha256sums = ${tar_sum}
	sha256sums = ${lic_sum}

pkgname = thrm-bin
EOF

echo "updated to $ver"
