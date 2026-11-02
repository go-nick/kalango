#!/usr/bin/env bash
# Install Wave Terminal from its official GitHub release RPM, at a pinned version.
# Wave doesn't sign this RPM, so the checksum catches a file changed after this pin.
set -euo pipefail

VERSION=0.14.5
SHA256=fea2046df8deb8c19ade09f22a3e3faa392b000d60c30b8849e2fb18f27a21d0
RPM="waveterm-linux-x86_64-$VERSION.rpm"

if [[ "$(rpm -q --qf '%{VERSION}' waveterm 2>/dev/null)" == "$VERSION" ]]; then
    echo "   $VERSION already installed"
    exit 0
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
curl -fsSL -o "$TMP/$RPM" "https://github.com/wavetermdev/waveterm/releases/download/v$VERSION/$RPM"
echo "$SHA256  $TMP/$RPM" | sha256sum -c --quiet
sudo zypper --non-interactive install --allow-unsigned-rpm "$TMP/$RPM"
