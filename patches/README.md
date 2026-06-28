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

## `0007-arechta-cu-debug-trace-and-protobuf-hardening.patch`

Adds opt-in production tracing for Cursor responses and hardens protobuf text extraction.

Requires `0001` through `0006` applied first.

Changes:

- `open-sse/executors/cursor.js`
  - `CURSOR_TRACE_RESPONSES=1` writes decoded Cursor frames, final content/reasoning/tool calls, and exact outgoing JSON/SSE to `DATA_DIR/logs/cursor/`
  - `CURSOR_TRACE_MAX_CHARS` caps large trace fields (default `200000`)
- `open-sse/utils/cursorProtobuf.js`
  - Safely skips invalid tool-call parses instead of aborting nested text extraction
  - Prevents field `1` inside a response (normal text) from becoming an empty completion when it is not a tool call

Debug one production repro:

```bash
CURSOR_TRACE_RESPONSES=1
CURSOR_STREAM_DEBUG=1
# redeploy, run one Cursor Agent request, then inspect:
ls -lt /opt/docker/9router/data/logs/cursor/
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

## `0003-arechta-cu-redacted-tool-wire.patch`

Fixes **real Cursor Auto wire format** seen in production: `<｜tool▁calls▁begin｜>`, `<｜tool▁sep｜>`, multiline key/value args (not only Kimi `<|tool_sep|>` inline).

Also normalizes fullwidth pipe / block-char variants (U+FF5C, U+2581) before parsing.

Requires `0001` + `0002` applied first.

Changes:

- `open-sse/utils/cursorComposerTools.js` — `redacted_tool_*` parsing, `normalizeCursorWireCharacters()`
- `tests/unit/cursor-composer-tools.test.js` — production-format fixtures (ASCII escapes)

## `0004-arechta-cu-lenient-tool-wire.patch`

Fixes **malformed Cursor Auto wire** still leaking after `0003`:

- Missing `<｜tool▁call▁begin｜>` wrapper (tool name glued to envelope)
- Corrupted tool name (`tead` → `Read`)
- Corrupted end tag (`<｜tool▁call▁ennd｜>` instead of `<｜tool▁call▁end｜>`)
- Full envelope stripped even when inner blocks are incomplete

Requires `0001` + `0002` + `0003` applied first.

Changes:

- `open-sse/utils/cursorComposerTools.js` — `parseLenientEnvelopeInner()`, `resolveToolName()`, `TOOL_CALLS_ENVELOPE_RE`
- `tests/unit/cursor-composer-tools.test.js` — production malformed stream fixture

Refresh upstream + re-apply:

```bash
bash scripts/sync-repository.sh
```

## `0005-arechta-cu-full-tool-audit.patch`

Full audit hardening from [Randomblock1/cursor-openai-api](https://github.com/Randomblock1/cursor-openai-api), [pwnapplehat/cursor-proxy-patched](https://github.com/pwnapplehat/cursor-proxy-patched), [timxx/Cursor-To-OpenAI](https://github.com/timxx/Cursor-To-OpenAI).

Requires `0001` + `0002` + `0003` + `0004` applied first.

Changes:

- `open-sse/utils/cursorComposerTools.js`
  - `findComposerToolMarker()` + `canonicalizeComposerToolMarkers()` (flexible `｜` / `▁` markers)
  - `toolMarkerPrefixIndex()` + SSE partial-marker buffering in `StreamingComposerFilter`
  - `sanitizeForParsing()`, `extractJsonObject()`, JSON / inline-bracket tool bodies
  - `parseToolCallsFromAnthropicIds()` (`toolu_bdrk_*` text fallback)
  - `normalizeToolArgumentsForSchema()` / `normalizeOpenAIToolCalls()` (arg remaps: `file_path`→`path`, etc.)
  - `getClientToolsFromBody()` wired through `finalizeAssistantOutput()`
- `open-sse/utils/cursorProtobuf.js` — protobuf `toolCallV2` (field 36) + legacy field 13; nested response scan
- `open-sse/executors/cursor.js` — pass client `tools[]` into finalize + streaming filter
- `tests/unit/cursor-composer-tools.test.js` — schema remap, JSON body, streaming buffer tests

Refresh upstream + re-apply:

```bash
bash scripts/sync-repository.sh
```

## `0006-arechta-cu-thinking-reasoning.patch`

Fixes **thinking/reasoning leak** for `cu/default` and Composer models: text before `</think>` was merged into visible `content` (0001 promote-all) instead of the expandable **Thought** panel.

Requires `0001` + `0002` + `0003` + `0004` + `0005` applied first.

Changes:

- `open-sse/utils/cursorModel.js`
  - `splitCursorThinkingSurface()` — split at `</think>` (and `\u003cthink\u003e` alias)
  - `mergeCursorAssistantRaw()` — merge protobuf text + thinking fields
  - `getCursorForwardThinkingMode()` — env `CURSOR_FORWARD_THINKING` (default `reasoning_content`)
  - `shouldPreserveReasoningWithContent()` — keep Thought panel when reasoning ≠ content
- `open-sse/utils/cursorComposerTools.js`
  - `resolveCursorAssistantParts()` — route reasoning vs content by mode
  - `StreamingComposerFilter.getReasoningDelta()` — SSE `delta.reasoning_content`
  - Strip `redacted_thinking` and `think` control tokens
- `open-sse/executors/cursor.js` — emit `reasoning_content` (JSON + SSE); fix empty-completion when only reasoning
- `open-sse/handlers/chatCore/nonStreamingHandler.js`, `sseToJsonHandler.js` — preserve split reasoning alongside content
- `tests/unit/cursor-default.test.js` — split fixtures (text field + thinking field)

Env (optional):

```bash
CURSOR_FORWARD_THINKING=reasoning_content   # default — Thought UI via reasoning_content
# off | content | both | reasoning_content
# content = legacy 0001 promote-all-to-content
```

**Deploy:** `repository/` is gitignored — after `git pull` you must run `bash scripts/sync-repository.sh` before `docker compose build`, or the container still runs old code.

Refresh upstream + re-apply:

```bash
bash scripts/sync-repository.sh
```
