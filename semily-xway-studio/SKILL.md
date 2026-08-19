---
name: semily-xway-studio
description: Use when a user asks to analyze WB competitors, create five marketplace covers from product/reference images, launch or monitor an XWAY image test, apply a statistically confirmed winner, or continue a winner-driven creative improvement cycle.
---

# Semily XWAY Studio

## Principle

Run one evidence-driven chain: WB analysis → five controlled covers → visible delivery → one approval → XWAY test → CTR decision → verified winner → next cycle. Use hosted `semily_xway` tools for live data and writes. Never claim a server action succeeded without tool evidence.

## Start

1. Require WB article/SKU and a product image. Accept a background/design reference when supplied.
2. Call `start_semily_test` immediately when attachments are present. Pass a third text/layout creative as `layout_reference`. Default to `openai/gpt-image-2` through Provod unless the user names another supported model.
3. Ask only for a missing SKU, missing required product image, or genuinely uncertain critical product text. Never ask the user to write an internal prompt.
4. If `semily_xway` is unavailable, prepare analysis/hypotheses only and state that launch, monitoring, and winner application are unavailable. Never request passwords, tokens, cookies, browser profiles, or database credentials in chat.

## Full workflow

1. Read [WB analysis](references/wb-analysis.md). Call `prepare_wb_analysis`, inspect the first 20 relevant organic WB cards, and persist them with `record_wb_analysis`. Do not generate before receiving `analysis_uuid`.
2. Read [creative generation](references/creative-generation.md). Build exactly five non-random hypotheses V1–V5 from observed WB patterns, prior cycle learning, and the current champion.
3. Generate all five via `confirm_hypotheses_and_start_generation` with `confirmed_texts=[]`. Poll `creative_set_status` in the same turn; do not create a generation monitor or ask the user to check later.
4. When reusable copy came from `layout_reference`, call `bind_layout_reference_copy` with transcribed blocks and forbidden promo/UI text; omit `source_sha256` so the server binds the persisted layout file. Do this before delivery and without another Provod call.
4. Inspect and QA all outputs. Retry only failed variants. Call `creative_set_result`, then call `creative_variant_result` separately for V1, V2, V3, V4, and V5.
5. Read [delivery and safety](references/safety-and-delivery.md). Show five actual images in chat. A filename, tool preview, or remote URL alone is not delivery.
6. After all five render, request one approval. Accept an unambiguous `ОК`, `OK`, `да`, `подтверждаю`, `утверждаю`, `одобряю`, or `запускай`. A correction request is not approval.
7. On approval, call `approve_completed_creatives_for_xway`, follow `next_action_tool`, and continue without asking for a second launch confirmation.
8. Read [XWAY experiments](references/xway-experiments.md). Launch champion + V1–V5, monitor hourly, apply only a qualified winner, and verify the main-image read-back.
9. After a winner, start the следующий цикл from that champion and create five new evidence-based challengers. Strengthen the winning mechanism; do not reset to random covers or repeat a proven loser.

## Non-negotiable rules

- Use text only when it is visibly verified on the supplied product/reference image or explicitly authorized product data. Промокод не копировать. Never invent a claim.
- Preserve product count, proportions, geometry, colors, logo, label artwork, and readable package text.
- Keep the current champion unchanged as control.
- CTR from XWAY is the primary decision metric. Выручка на 1 000 показов — не использовать because it cannot be attributed reliably to the image active at that time.
- State-changing calls require server idempotency and reverse verification.

## Completion

For generation, complete only after five covers are visibly embedded. For launch, complete only after XWAY read-back confirms six frames. For winner application, complete only after the main image read-back matches the winning artifact.
