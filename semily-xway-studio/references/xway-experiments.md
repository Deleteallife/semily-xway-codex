# XWAY experiments

## Launch

After the single user approval, call `approve_completed_creatives_for_xway` and follow its `next_action_tool`. Resolve the product from the WB SKU and read back exactly six frames: unchanged champion plus V1–V5. Do not stop or overwrite an unrelated active test.

## Monitoring and decision

Collect hourly, idempotent snapshots of impressions, clicks, CTR, rotations, status, and frame identity. Report control and V1–V5 briefly. Missing intervals remain missing.

CTR is primary. Confirm a winner only when the control and candidate each have at least 1500 impressions, uplift is at least +1,5 percentage points, and p-value < 0,05. Also obey stricter server-side sequential/multiple-comparison checks when returned. Never choose from appearance, cross-test CTR, revenue, or revenue per 1,000 impressions.

If the server returns a qualified winner, call `apply_winner`, verify that XWAY stopped/finalized the intended test, set the winning main image, and read it back. If the test is terminal without a winner, keep the champion.

## Continuous cycle

Maintain one SKU-scoped cycle automation. After a verified winner or terminal no-winner, begin fresh WB analysis. A new round is the current champion plus exactly five new evidence-driven challengers. On authentication loss, preserve state and pause; do not create a duplicate monitor or test.

OAuth requests `mcp:use` and `offline_access`; API authorization still depends on `mcp:use`.
