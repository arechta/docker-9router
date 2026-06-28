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

If upstream drifts, regenerate after editing `repository/`:

```bash
cd repository
git add -A && git diff --cached > ../patches/0001-arechta-cu-default-fix.patch
git reset HEAD
```
