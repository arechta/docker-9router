# 9Router source patches

Patches apply on top of [decolua/9router](https://github.com/decolua/9router) `master` inside `repository/`.

## `0001-arechta-cu-default-fix.patch`

Rebased from [jahrulnr/9router#1](https://github.com/jahrulnr/9router/pull/1) (commits `145c64cf` + `9234815`), adapted for upstream **v0.5.12**.

Fixes **cu/default** returning **0 output tokens** when Cursor thinking content is not promoted to visible assistant text ([decolua#1077](https://github.com/decolua/9router/issues/1077)).

Changes:

- `open-sse/utils/cursorModel.js` — model normalization; `default`/`auto` upstream id
- `open-sse/executors/cursor.js` — promote thinking, Agent mode for default, 502 on empty completion
- `open-sse/services/model.js` — infer `default`/`auto` as Cursor provider
- `src/app/api/models/test/ping.js` — stream + validate Cursor model pings
- Unit tests under `tests/unit/`

Refresh upstream + re-apply:

```bash
bash scripts/sync-repository.sh
```

## `0002-arechta-cu-composer-agent-tools.patch`

Adds **agentic / tool-calling support** for `cu/default`, Composer, and `-thinking` Cursor models on OpenAI-compatible `/v1/chat/completions` routes.

Fixes leaked Composer control tokens (`<|final|>`, `<|tool_calls_begin|>`, `<|tool_sep|>`) and converts Kimi-style embedded tool markers into OpenAI `tool_calls` with `finish_reason: "tool_calls"`.

Requires `0001` applied first.

Changes:

- `open-sse/utils/cursorComposerTools.js` — parse/strip Composer tokens; streaming filter
- `open-sse/utils/cursorModel.js` — `normalizePromotedText()` for `<|final|>` + redacted thinking
- `open-sse/executors/cursor.js` — integrate text tool parsing (JSON + SSE); force Agent when client sends `tools`
- Unit tests: `cursor-composer-tools.test.js`, extended `cursor-default.test.js`

Refresh upstream + re-apply:

```bash
bash scripts/sync-repository.sh
```

If upstream drifts, regenerate after editing `repository/`:

```bash
cd repository
git add -A && git diff --cached > ../patches/0001-arechta-cu-default-fix.patch
git reset HEAD
```

For `0002` only (after `0001` baseline in a clean upstream clone):

```bash
git apply ../patches/0001-arechta-cu-default-fix.patch
# copy edited files into repository/
git add open-sse/utils/cursorComposerTools.js open-sse/utils/cursorModel.js open-sse/executors/cursor.js tests/unit/cursor-composer-tools.test.js tests/unit/cursor-default.test.js
git diff --cached > ../patches/0002-arechta-cu-composer-agent-tools.patch
git reset HEAD
```
