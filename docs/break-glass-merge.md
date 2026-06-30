# Break-glass merge procedure

Use only when the merge queue is stuck and all checks pass.

## Trigger conditions
- All CI checks pass (including required `ci / ci`)
- PR is approved
- PR has been stuck in BLOCKED for > 30 minutes
- No other PRs in the queue

## Procedure

1. **Disable the merge queue ruleset**
   - Go to: `/organizations/{org}/settings/repos/{repo}/rules`
   - Find `merge-queue` ruleset → Set enforcement to `Disabled`
   
2. **Merge the PR**
   - `gh pr review {pr} -R {repo} --approve`
   - `gh pr merge {pr} -R {repo} --squash`

3. **Re-enable the merge queue**
   - Same page → Set enforcement back to `Active`

4. **Document the incident**
   - File an issue with the PR number and date
   - Note: this should be a rare event

## Why the merge queue gets stuck
- Stale merge queue entry (checks completed after queue entry was created)
- Orphaned PR in the queue (another PR was removed but left state)
- GitHub Actions runner delays

## Prevention
- Ensure all checks run before adding to merge queue
- Monitor queue depth: `bin/merge-monitor --watch`
