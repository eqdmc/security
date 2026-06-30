#!/usr/bin/env bash
# dnf adapter — Fedora/RHEL package adapter for eqdmc/security vetting.
# Usage: dnf.sh <package-name> [version]
# Output: JSON metadata to stdout
set -euo pipefail

PKG="${1:?Usage: dnf.sh <package-name> [version]}"
VER="${2:-}"

# Query dnf for package info
pkg_data=$(dnf info "$PKG" 2>/dev/null || true)
pkg_installed=$(rpm -qi "$PKG" 2>/dev/null || true)

# Extract metadata — use grep/awk with fallback
_safe_field() {
  local field="$1"
  local data="$2"
  echo "$data" | grep "^$field" | awk -F': ' '{print $2}' | head -1 || true
}

name=$(_safe_field "Name" "$pkg_data") && [ -z "$name" ] && name="$PKG"
version=$(_safe_field "Version" "$pkg_data") || true
release=$(_safe_field "Release" "$pkg_data") || true
arch=$(_safe_field "Architecture" "$pkg_data") || true
license=$(_safe_field "License" "$pkg_data") || license="unknown"
repo=$(_safe_field "Repository" "$pkg_data") || repo="unknown"
summary=$(_safe_field "Summary" "$pkg_data") || summary=""
url=$(_safe_field "URL" "$pkg_data") || url=""
build_time=$(_safe_field "Build Date" "$pkg_installed") || build_time="unknown"
vendor=$(_safe_field "Vendor" "$pkg_data") || vendor="unknown"

# Categorize repo source
case "$repo" in
  *fedora*|*updates*|*rpmfusion*)
    repo_type="official"
    ;;
  *copr*)
    repo_type="copr"
    ;;
  *)
    repo_type="third-party"
    ;;
esac

# Build GitHub slug from URL if available
gh_slug=""
if [ -n "$url" ] && [[ "$url" =~ github\.com[:/]([^/]+)/([^/]+) ]]; then
  gh_slug="${BASH_REMATCH[1]}/${BASH_REMATCH[2]%.git}"
fi

# Check for install scripts
has_scripts=0
if rpm -q --scripts "$PKG" 2>/dev/null | grep -qE "postinstall|preinstall"; then
  has_scripts=1
fi

# Official Fedora packages are reviewed
if [ "$repo_type" = "official" ]; then
  review_url="https://src.fedoraproject.org/rpms/$PKG"
else
  review_url=""
fi

# Output JSON
cat << JSON
{
  "ecosystem": "dnf",
  "package": "$name",
  "version": "${version}-${release}",
  "metadata": {
    "name": "$name",
    "license": "$license",
    "repo_url": "$url",
    "gh_slug": "$gh_slug",
    "publish_time": "$build_time",
    "maintainer_count": 1,
    "maintainers": ["Fedora Project"],
    "has_install_scripts": $has_scripts,
    "repo_type": "$repo_type",
    "repo_source": "$repo",
    "architecture": "$arch",
    "vendor": "$vendor",
    "summary": "$summary",
    "review_url": "$review_url",
    "fedora_package_url": "https://packages.fedoraproject.org/pkgs/$PKG"
  },
  "summary": "$summary"
}
JSON
