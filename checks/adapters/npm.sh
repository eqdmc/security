#!/usr/bin/env bash
# npm registry adapter for eqdmc/security vetting system
# Usage: npm.sh <package> [version]
# Output: JSON metadata to stdout
set -euo pipefail

PKG="${1:?Usage: npm.sh <package> [version]}"
VER="${2:-latest}"

reg=$(curl -sf "https://registry.npmjs.org/${PKG}/${VER}" 2>/dev/null || echo '{}')
root=$(curl -sf "https://registry.npmjs.org/${PKG}" 2>/dev/null || echo '{}')

license=$(echo "$reg" | jq -r '.license // "unknown"')
pub_time=$(echo "$root" | jq -r ".time[\"${VER}\"] // \"unknown\"")
maintainer_count=$(echo "$root" | jq '[.maintainers // [] | .[].name] | unique | length')
maintainers=$(echo "$root" | jq -c '[.maintainers // [] | .[].name] | unique')
repo_url=$(echo "$reg" | jq -r '.repository.url // .repository // ""' | sed 's|^git+||;s|\.git$||;s|^ssh://git@|https://|;s|^git://|https://|')
has_scripts=$(echo "$reg" | jq 'if .scripts then (.scripts | keys | map(select(. == "preinstall" or . == "postinstall" or . == "install")) | length) else 0 end')
name=$(echo "$reg" | jq -r '.name // .')
version=$(echo "$reg" | jq -r '.version // .')

gh_slug=""
if [[ "$repo_url" =~ github\.com[:/]([^/]+)/([^/]+) ]]; then
  gh_slug="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
fi

jq -n \
  --arg name "$name" --arg version "$version" --arg ecosystem "npm" \
  --arg license "$license" --arg repo_url "$repo_url" --arg gh_slug "$gh_slug" \
  --arg pub_time "$pub_time" --argjson maintainer_count "$maintainer_count" \
  --argjson maintainers "$maintainers" --argjson has_scripts "$has_scripts" \
  '{
    ecosystem: $ecosystem, package: $name, version: $version,
    metadata: {
      license: $license, repo_url: $repo_url, gh_slug: $gh_slug,
      publish_time: $pub_time, maintainer_count: $maintainer_count,
      maintainers: $maintainers, has_install_scripts: $has_scripts
    }
  }'
