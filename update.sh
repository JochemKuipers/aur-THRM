#!/usr/bin/env bash
# Rebuild PKGBUILD/.SRCINFO from TIANLI0/THRM's PKGBUILD + the portable release.
set -euo pipefail

cd "$(dirname "$0")"

api="${GITHUB_API_URL:-https://api.github.com}/repos/TIANLI0/THRM/releases/latest"
tag=$(curl -fsSL "$api" | jq -r '.tag_name')
[[ -n "$tag" && "$tag" != null ]] || { echo "failed to resolve latest tag" >&2; exit 1; }
ver="${tag#v}"
ver="${ver#V}"

echo "syncing $ver from upstream PKGBUILD"

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

curl -fsSL "https://raw.githubusercontent.com/TIANLI0/THRM/v${ver}/PKGBUILD" -o "$tmp/up.PKGBUILD"
curl -fsSL "https://github.com/TIANLI0/THRM/releases/download/v${ver}/THRM-linux-amd64-portable.tar.gz" -o "$tmp/portable.tar.gz"
curl -fsSL "https://raw.githubusercontent.com/TIANLI0/THRM/v${ver}/packaging/linux/thrm.desktop" -o "$tmp/thrm.desktop"
curl -fsSL "https://raw.githubusercontent.com/TIANLI0/THRM/v${ver}/LICENSE" -o "$tmp/LICENSE"

tar_sum=$(sha256sum "$tmp/portable.tar.gz" | awk '{print $1}')
desk_sum=$(sha256sum "$tmp/thrm.desktop" | awk '{print $1}')
lic_sum=$(sha256sum "$tmp/LICENSE" | awk '{print $1}')

python3 - "$tmp/up.PKGBUILD" "$ver" "$tar_sum" "$desk_sum" "$lic_sum" <<'PY'
import re, sys
from pathlib import Path

up, ver, tar_sum, desk_sum, lic_sum = sys.argv[1:6]
text = Path(up).read_text()

text = re.sub(
    r"^# Maintainer:.*",
    "# Maintainer: Jochem Kuipers <jochem@kuipers.cc>\n# Upstream: TIANLI0 <wutianli@tianli0.top>",
    text,
    count=1,
    flags=re.M,
)
text = re.sub(
    r"(?:^# 版本.*\n(?:^# .*\n)*)?^pkgver=.*\n(?:: \"\$\{pkgver:=0\.0\.0\}\"\n)?",
    f"pkgver={ver}\n",
    text,
    count=1,
    flags=re.M,
)
text = re.sub(
    r"(?:^# This PKGBUILD.*\n(?:^# .*\n)*)?^source=\([^)]*\)\nsha256sums=\([^)]*\)\n",
    f"""source=(
  "https://github.com/TIANLI0/THRM/releases/download/v${{pkgver}}/THRM-linux-amd64-portable.tar.gz"
  "thrm.desktop::https://raw.githubusercontent.com/TIANLI0/THRM/v${{pkgver}}/packaging/linux/thrm.desktop"
  "LICENSE::https://raw.githubusercontent.com/TIANLI0/THRM/v${{pkgver}}/LICENSE"
)
sha256sums=(
  '{tar_sum}'
  '{desk_sum}'
  '{lic_sum}'
)

prepare() {{
  mv "$srcdir/THRM-linux-amd64/thrm" "$srcdir/thrm"
  mv "$srcdir/THRM-linux-amd64/thrm-core" "$srcdir/thrm-core"
  mv "$srcdir/THRM-linux-amd64/99-flydigi-fan.rules" "$srcdir/99-flydigi-fan.rules"
  mv "$srcdir/THRM-linux-amd64/appicon.png" "$srcdir/thrm.png"
}}

""",
    text,
    count=1,
    flags=re.M,
)

Path("PKGBUILD").write_text(text)
PY

printsrcinfo() {
  if command -v makepkg >/dev/null 2>&1; then
    if [[ "$(id -u)" == 0 ]]; then
      local d
      d=$(mktemp -d)
      cp PKGBUILD "$d/"
      chown nobody "$d" "$d/PKGBUILD"
      (cd "$d" && su nobody -s /bin/bash -c 'makepkg --printsrcinfo')
    else
      makepkg --printsrcinfo
    fi
  elif command -v docker >/dev/null 2>&1; then
    docker run --rm -v "$PWD/PKGBUILD":/pkg/PKGBUILD:ro -w /pkg archlinux:base-devel \
      bash -c 'install -d -o nobody /tmp/p && cp /pkg/PKGBUILD /tmp/p && cd /tmp/p && su nobody -s /bin/bash -c "makepkg --printsrcinfo"'
  else
    echo "need makepkg or docker to generate .SRCINFO" >&2
    exit 1
  fi
}

printsrcinfo > .SRCINFO.tmp
mv .SRCINFO.tmp .SRCINFO
echo "updated to $ver"
