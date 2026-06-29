#!/usr/bin/env bash
# Flathub registry adapter for eqdmc/security vetting system
# Enriches metadata from GitHub API when gh_slug is available.
# Usage: flathub.sh <app-id> [version]
# Output: JSON metadata to stdout
set -euo pipefail

APP_ID="${1:?Usage: flathub.sh <app-id> [version]}"
VER="${2:-stable}"

# Query Flathub API v2
appdata=$(curl -sf "https://flathub.org/api/v2/appstream/${APP_ID}" 2>/dev/null || echo '{}')
appdata_full=$(curl -sf "https://flathub.org/api/v2/apps/${APP_ID}" 2>/dev/null || echo '{}')

name=$(echo "$appdata" | jq -r '.name // .id // "'"$APP_ID"'"')
license=$(echo "$appdata" | jq -r '.project_license // "unknown"')
repo_url=$(echo "$appdata" | jq -r '(.urls.homepage // (.urls["donation"] // ""))' 2>/dev/null || echo "")
[ -z "$repo_url" ] && repo_url=$(echo "$appdata" | jq -r '.urls // empty | to_entries | map(.value) | first // ""')
developer_name=$(echo "$appdata" | jq -r '.developer_name // "unknown"')

# GitHub slug from vcs_browser, repo_url, or app ID convention
gh_slug=""
vcs_url=$(echo "$appdata" | jq -r '.urls.vcs_browser // ""')
if [ -n "$vcs_url" ] && [[ "$vcs_url" =~ github\.com[:/]([^/]+)/([^/]+) ]]; then
  gh_slug="${BASH_REMATCH[1]}/${BASH_REMATCH[2]%.git}"
elif [ -n "$repo_url" ] && [[ "$repo_url" =~ github\.com[:/]([^/]+)/([^/]+) ]]; then
  gh_slug="${BASH_REMATCH[1]}/${BASH_REMATCH[2]%.git}"
elif echo "$APP_ID" | grep -qE '^org\.|^io\.|^com\.'; then
  slug=$(echo "$APP_ID" | sed 's/^[a-z]*\.//;s/\.[^.]*$//')
  gh_slug="$slug/$slug"
fi

# Flathub apps are sandboxed — no install scripts
has_scripts=0

# Enrich from GitHub API when slug is available
pub_time=""
maintainer_count=1
maintainers=$(echo "$appdata" | jq -c '[.developer_name // "'"$developer_name"'"]')
stars=0
forks=0

if [ -n "$gh_slug" ] && command -v gh &>/dev/null; then
  # Fetch repo info — use tmpfile to avoid `||` concatenating error JSON + fallback
  gh_tmp=$(mktemp) && trap 'rm -f "$gh_tmp"' RETURN
  if gh api "repos/${gh_slug}" --jq '{created: .created_at, pushed: .pushed_at, stars: .stargazers_count, forks: .forks_count, language: .language}' > "$gh_tmp" 2>/dev/null; then
    gh_data=$(<"$gh_tmp")
    gh_created=$(echo "$gh_data" | jq -r '.created // ""')
    [ -n "$gh_created" ] && pub_time="$gh_created"

    stars=$(echo "$gh_data" | jq -r '.stars // 0')
    forks=$(echo "$gh_data" | jq -r '.forks // 0')

    # Contributor count as maintainer proxy
    if gh api "repos/${gh_slug}/contributors" --jq 'length' > "$gh_tmp" 2>/dev/null; then
      gh_contributors=$(<"$gh_tmp")
      gh_contributors="${gh_contributors//[!0-9]/}"
      if [ "${gh_contributors:-0}" -gt 0 ] 2>/dev/null; then
        maintainer_count="$gh_contributors"
        if gh api "repos/${gh_slug}/contributors" --jq '[.[].login] | .[0:10]' > "$gh_tmp" 2>/dev/null; then
          maintainers=$(<"$gh_tmp")
        fi
      fi
    fi
  fi
fi

[ -z "$pub_time" ] && pub_time=$(echo "$appdata_full" | jq -r '.released // ""')
[ -z "$pub_time" ] && pub_time=$(echo "$appdata" | jq -r '.released // ""')
[ -z "$pub_time" ] && pub_time="unknown"

jq -n \
  --arg name "$name" --arg version "$VER" --arg ecosystem "flathub" \
  --arg license "$license" --arg repo_url "$repo_url" --arg gh_slug "$gh_slug" \
  --arg pub_time "$pub_time" --argjson maintainer_count "$maintainer_count" \
  --argjson maintainers "$maintainers" --argjson has_scripts "$has_scripts" \
  --argjson stars "$stars" --argjson forks "$forks" \
  '{
    ecosystem: $ecosystem, package: $name, version: $version,
    metadata: {
      license: $license, repo_url: $repo_url, gh_slug: $gh_slug,
      publish_time: $pub_time, maintainer_count: $maintainer_count,
      maintainers: $maintainers, has_install_scripts: $has_scripts,
      stars: $stars, forks: $forks
    }
  }'
