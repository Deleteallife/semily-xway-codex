# Safety and image delivery

## Always show the images

Call `creative_set_result`, then `creative_variant_result` separately for V1–V5. Inspect each full-resolution result. Embed all five images in the final response.

If direct image content is unavailable, download each approved artifact into a task-specific local folder, verify a non-zero file and valid image, then render Markdown image tags using абсолютные локальные пути. Remote Markdown URLs, filenames, placeholders, or tool status cards alone do not count.

Present each image under its label and a one-line hypothesis. Do not finish with broken image placeholders.

## Writes

Before launch or applying a winner, require persisted authorization and server idempotency. Reverse-check every XWAY write. If a write times out with unknown outcome, inspect current state before retrying. Never expose OAuth tokens, refresh tokens, CSRF values, database credentials, or browser sessions.
