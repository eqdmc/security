# Tool Decision Lifecycle

Every tool selected through rax/select goes through a complete lifecycle.
Decisions are documented, outcomes tracked, and criteria refined over time.

## The Cycle

```
     ┌─────────────────────────────────────────────────────┐
     │                                                     │
     ▼                                                     │
  SELECT ──► VET ──► INSTALL ──► USE ──► REVIEW ──► RETAIN │
     │                                                     │
     └─────────── REPLACE (new SELECT cycle) ──────────────┘
```

### Phase 1: SELECT
- Identify need and candidate tools
- Score each candidate against criteria from vetting-policy.json
- Present scored options via rax/select
- Human chooses
- Create Tool Decision Record (TDR)

### Phase 2: VET
- Run chosen package through vetting gates
- If blocked: return to SELECT with new info
- If approved: proceed to install

### Phase 3: INSTALL
- Install via vet-install (approved path only)
- Update machine manifest
- Configure for use

### Phase 4: USE
- Tool is in production
- Collect feedback: what works, what doesn't
- Log issues and workarounds

### Phase 5: REVIEW
- Scheduled review (7/30/90 days post-install)
- Evaluate: did the tool meet expectations?
- Compare predicted outcomes vs actual results
- Update the TDR with findings

### Phase 6: RETAIN or REPLACE
- If satisfied: retain, archive TDR
- If not: start new SELECT cycle with updated criteria
- The original TDR becomes the "lessons learned" input

## Tool Decision Record (TDR)

Each selection produces a TDR document:

```yaml
tdr:
  id: "TDR-2026-07-01-restic"
  title: "Encrypted backup tool"
  status: "active"  # active | under-review | replaced | archived
  selection_date: "2026-07-01"
  review_date: "2026-07-08"  # 7-day review
  
  candidates:
    - name: restic
      total_score: 77
      scores: {license: 20, maintenance: 10, community: 15, ...}
      verdict: APPROVED
    - name: borgbackup
      total_score: 58
      verdict: BLOCKED (license)
      
  selected: restic
  rationale: "Apache-2.0 license, active maintenance, large community"
  expected_outcomes:
    - "Meet backup requirements within configurable threshold"
    - "CLI-first workflow"
    - "Cloud storage support"
    
  review:
    date: "2026-07-08"
    outcome: "meets_expectations"  # meets | partial | fails
    actual_outcomes:
      - "Fully meets backup requirements"
      - "CLI works as expected"
      - "S3 backend configured"
    lessons: "Document S3 configuration steps for faster setup"
    
  verdict: "retain"  # retain | replace
```

## Review Schedule

| Review | Timing | Purpose |
|--------|--------|---------|
| Quick check | 7 days | Major issues? Meets basic needs? |
| Full review | 30 days | Performance, reliability, integration |
| Long-term | 90 days | Maintainability, community health |
| Annual | 365 days | Still best choice? New alternatives? |

## Criteria Evolution

The scoring criteria in vetting-policy.json are not static.
After each review cycle, analyze:

- Which criteria were most predictive of good outcomes?
- Which criteria were irrelevant or misleading?
- Should new criteria be added?

This feedback loop improves future selections.
