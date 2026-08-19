# Creative generation

## Hypotheses

Create exactly пять challengers V1–V5. Each changes one primary lever and must differ strongly in background construction, spatial composition, depth, product staging, text hierarchy, or badge treatment. Use the stored WB evidence and prior cycle learning. Variants must remain distinguishable at a 150 px thumbnail.

For later rounds, use the winner as the visual baseline. Preserve its winning mechanism and vary unresolved levers around it. Do not randomly restyle, return to a weaker direction, or generate near-duplicates.

## Product and text

- Preserve product identity, quantity, geometry, colors, logo, label composition, and exact verified package text.
- Use text only from the supplied product/reference image or explicitly authorized product data.
- Промокод не копировать, even when visible in a reference creative.
- Never invent ingredients, efficacy, medical claims, measurements, guarantees, discounts, or badges.
- Leave intentional safe space for overlays without covering the product.

## Generation and QA

Call `confirm_hypotheses_and_start_generation` with `workflow_uuid`, `analysis_uuid`, and `confirmed_texts=[]`. Copy from `layout_reference` is never a chat whitelist and must not be passed through `confirmed_texts`.

Poll `creative_set_status` until terminal. If a `layout_reference` was supplied for reusable copy, call `bind_layout_reference_copy` before delivery. Pass only visually transcribed blocks, put promo codes and marketplace UI strings in `forbidden_texts`, and omit `source_sha256`; the server computes and binds the exact persisted layout hash. This deterministic overlay step does not call Provod again.

Inspect full-resolution V1–V5 for product identity, label accuracy, readability, contact shadows, crop, and thumbnail clarity. Submit one complete `submit_creative_identity_review` batch. Use `retry_creative_variants` for failed jobs and `revise_creative_variants` for defective completed variants; never regenerate the complete set for one failure.
