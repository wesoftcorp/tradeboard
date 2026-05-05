# Rebranding: OpenAlgo → Tradeboard

**Date:** 2026-05-05  
**Author:** Automated via Antigravity (AI assistant)  
**Git Repo:** https://github.com/wesoftcorp/tradeboard

---

## Overview

This document records every change made when rebranding the project from **OpenAlgo** to **Tradeboard**, and the URL from **openalgo.in** to **wesoftcorp.com**.

---

## Replacement Rules Applied

The following substitutions were performed in priority order (most specific first to avoid double-replacement):

| # | Find | Replace | Scope |
|---|------|---------|-------|
| 1 | `openalgoUI` | `tradeboardUI` | Python package name |
| 2 | `openalgo_mcp_server` | `tradeboard_mcp_server` | Internal module name |
| 3 | `get_openalgo_version` | `get_tradeboard_version` | MCP tool name |
| 4 | `docs.openalgo.in` | `docs.wesoftcorp.com` | Documentation subdomain |
| 5 | `openalgo.in/docs` | `wesoftcorp.com/docs` | Docs URL path |
| 6 | `openalgo.in` | `wesoftcorp.com` | Primary domain |
| 7 | `marketcalls/openalgo` | `wesoftcorp/tradeboard` | Old GitHub repo |
| 8 | `github.com/openalgo/openalgo` | `github.com/wesoftcorp/tradeboard` | Alt GitHub repo |
| 9 | `OPENALGO_` | `TRADEBOARD_` | All uppercase env var prefixes |
| 10 | `OpenAlgo` | `Tradeboard` | Title-case brand name |
| 11 | `openalgo` | `tradeboard` | Lowercase brand name (general) |

---

## Deliberate Exclusions

| Item | Reason |
|------|--------|
| `openalgo==1.0.49` (in `pyproject.toml`) | This is a **third-party PyPI package** — not our brand. Changing it would break `pip install`. |
| `.venv/` directory | Virtual environment — not project source |
| `myenv/` directory | Virtual environment — not project source |
| `.git/` directory | Git internals |
| `uv.lock` | Package lock file — auto-generated, contains PyPI package names |
| `__pycache__/` directories | Compiled bytecode — auto-regenerated |
| `node_modules/` | Frontend dependencies |

---

## Files & Directories Changed

### Core Configuration

| File | What Changed |
|------|-------------|
| `pyproject.toml` | `name = "openalgoUI"` → `name = "tradeboardUI"` |
| `.sample.env` | All `OPENALGO_PLACEHOLDER_*` strings → `TRADEBOARD_PLACEHOLDER_*` |
| `docker-compose.yaml` | Service/image name references |
| `Dockerfile` | Any brand references |
| `.github/` files | CI/CD workflow references |

### Python Source Files

| File / Pattern | What Changed |
|----------------|-------------|
| `utils/version.py` | Comment: `OpenAlgo` → `Tradeboard` |
| `utils/session.py` | Comment: `OpenAlgo` → `Tradeboard` |
| `utils/env_check.py` | `OPENALGO_PLACEHOLDER_*` → `TRADEBOARD_PLACEHOLDER_*`, URL refs, brand name in messages |
| `utils/constants.py` | `docs.openalgo.in` URL in comment |
| `utils/logging.py` | Log filename `openalgo_{date}.log` → `tradeboard_{date}.log` |
| `utils/email_utils.py` | Brand name in email subject lines and HTML body |
| `utils/health_monitor.py` | JSON key `"openalgo"` → `"tradeboard"` |
| `utils/mcp_tool_registry.py` | `OPENALGO_MCP_HTTP_BOOT` → `TRADEBOARD_MCP_HTTP_BOOT`, module name, tool name |
| `utils/mpp_slab.py` | Comment: brand name |
| `utils/ngrok_manager.py` | Comment: brand name |
| `utils/oauth_codes.py` | Comment: brand name |
| `utils/ip_helper.py` | Comment: brand name |
| `app.py` | `OPENALGO_MCP_HTTP_BOOT` → `TRADEBOARD_MCP_HTTP_BOOT` |
| `mcp/mcpserver.py` | `OPENALGO_MCP_HTTP_BOOT` env var, URL comment |
| `blueprints/mcp_http.py` | `OPENALGO_MCP_HTTP_BOOT` env var |
| `blueprints/mcp_oauth.py` | `docs.openalgo.in` URLs |
| `cors.py` | Any URL references |
| `csp.py` | Any URL references |

### Broker Mapping Files (~100+ files)

All files matching `broker/*/mapping/transform_data.py` and `broker/*/mapping/margin_data.py` had their header comment updated:

```python
# Before:
# Mapping OpenAlgo API Request https://openalgo.in/docs

# After:
# Mapping Tradeboard API Request https://wesoftcorp.com/docs
```

### Strategy Files

| File | What Changed |
|------|-------------|
| `strategies/examples/simple_ema_strategy.py` | `OPENALGO_API_KEY` → `TRADEBOARD_API_KEY` |

### Test Files

| File | What Changed |
|------|-------------|
| `test/test_broker.py` | `OPENALGO_API_KEY` → `TRADEBOARD_API_KEY`, `OPENALGO_HOST` → `TRADEBOARD_HOST` |
| `test/test_mstock.py` | `OPENALGO_API_KEY` → `TRADEBOARD_API_KEY` |
| `test/test_python_strategy_edge_cases.py` | `OPENALGO_STRATEGY_EXCHANGE` → `TRADEBOARD_STRATEGY_EXCHANGE` |

### Install / Upgrade Scripts

| File | What Changed |
|------|-------------|
| `install/install.sh` | Brand name, URLs, `OPENALGO_PATH` → `TRADEBOARD_PATH` variable |
| `install/install-docker.sh` | Brand name, URLs |
| `install/update.sh` | `OPENALGO_PATH` → `TRADEBOARD_PATH` variable, placeholder strings, URLs |
| `install/update.bat` | Windows equivalent |
| `install/docker-run.sh` | Brand name, URLs |
| `install/docker-run.bat` | Brand name, URLs |
| `install/README.md` | Brand name, URLs |
| `install/Docker-install-readme.md` | Brand name, URLs |
| `install/Remote-MCP-readme.md` | Brand name, URLs |
| `start.sh` | `OPENALGO_PLACEHOLDER_*` → `TRADEBOARD_PLACEHOLDER_*` |
| `docker-build.sh` | Brand name, image references |
| `docker-build.bat` | Brand name, image references |
| `upgrade/README.md` | Brand name |
| `upgrade/migrate_*.py` | Any brand references in comments |
| `upgrade/rotate_pepper.py` | Brand references |

### Frontend

| File | What Changed |
|------|-------------|
| `frontend/src/config/navigation.ts` | `docs.openalgo.in` → `docs.wesoftcorp.com` |

### Documentation

| File | What Changed |
|------|-------------|
| `README.md` | Brand name throughout, URLs, GitHub repo links |
| `CONTRIBUTING.md` | Brand name, URLs |
| `DOCKER_README.md` | Brand name, URLs |
| `INSTALL.md` | Brand name, URLs |
| `SECURITY.md` | `openalgo.in` → `wesoftcorp.com` |
| `CLAUDE.md` | Brand name, URLs |
| `docs/CHANGELOG.md` | Brand name in historical entries |
| `docs/userguide/**/*.md` | All user-facing docs with brand/URL refs |
| `docs/design/**/*.md` | All design docs |
| `docs/prompt/*.md` | All prompt docs |
| `docs/api/README.md` | API documentation |
| `docs/docker/README.md` | Docker docs |
| `docs/broker-integration-guide.md` | Brand/URL refs |
| `docs/xtsapi.md` | URL refs |
| `docs/releases/version-*.md` | Release notes |
| `docs/installation-guidelines/**/*.md` | Installation guides |
| `frontend/public/docs/gocharting_webhook_setup.md` | URL refs |

### Examples

| File | What Changed |
|------|-------------|
| `examples/python/cagr_heatmap.py` | Author comment URL |

### Websocket Proxy

| File | What Changed |
|------|-------------|
| `websocket_proxy/server.py` | Brand references |
| `websocket_proxy/mapping.py` | Brand references |

---

## Directory / Folder Renames

| Old Name | New Name | Action |
|----------|----------|--------|
| `openalgoUI.egg-info/` | `tradeboardUI.egg-info/` | Renamed (run: `Rename-Item openalgoUI.egg-info tradeboardUI.egg-info`) |

---

## Environment Variables — Before & After

> **IMPORTANT:** If you have a running `.env` file with these variable names, update them manually OR re-run setup.

| Old Variable | New Variable |
|-------------|-------------|
| `OPENALGO_MCP_HTTP_BOOT` | `TRADEBOARD_MCP_HTTP_BOOT` |
| `OPENALGO_API_KEY` | `TRADEBOARD_API_KEY` |
| `OPENALGO_HOST` | `TRADEBOARD_HOST` |
| `OPENALGO_STRATEGY_EXCHANGE` | `TRADEBOARD_STRATEGY_EXCHANGE` |
| `OPENALGO_PLACEHOLDER_APP_KEY_REGENERATE_BEFORE_USE` | `TRADEBOARD_PLACEHOLDER_APP_KEY_REGENERATE_BEFORE_USE` |
| `OPENALGO_PLACEHOLDER_API_KEY_PEPPER_REGENERATE_BEFORE_USE` | `TRADEBOARD_PLACEHOLDER_API_KEY_PEPPER_REGENERATE_BEFORE_USE` |

---

## MCP Tool Name Change

| Old | New |
|-----|-----|
| `get_openalgo_version` | `get_tradeboard_version` |
| Module: `openalgo_mcp_server` | Module: `tradeboard_mcp_server` |
| Env: `OPENALGO_MCP_HTTP_BOOT=1` | Env: `TRADEBOARD_MCP_HTTP_BOOT=1` |

> **Note:** Any external MCP clients configured to call `get_openalgo_version` must be updated to use `get_tradeboard_version`.

---

## What Was NOT Changed

1. **`openalgo==1.0.49`** in `pyproject.toml` — this is the [OpenAlgo Python SDK](https://pypi.org/project/openalgo/) published on PyPI. It is a third-party dependency, not our brand. Changing it would break installation.

2. **Content inside `.venv/`, `myenv/`** — virtual environment files are auto-generated.

3. **`uv.lock`** — package lock file auto-generated by `uv`. Run `uv lock` to regenerate after any dependency changes.

4. **Historical git commit messages** — cannot be rewritten without a full `git filter-branch` (not recommended).

---

## Manual Steps After Automated Rebranding

1. **Rename egg-info folder** (if it exists):
   ```powershell
   Rename-Item "d:\Code\VS Code\tradeboard\openalgoUI.egg-info" "tradeboardUI.egg-info"
   ```

2. **Reinstall the package** (to refresh the egg-info):
   ```bash
   pip install -e . --no-deps
   # or
   uv sync
   ```

3. **Update your `.env` file** — if your live `.env` uses `OPENALGO_*` variable names, replace them with `TRADEBOARD_*` equivalents (see table above).

4. **Update external MCP clients** — any Claude Desktop or other MCP client configs referencing `get_openalgo_version` or `OPENALGO_MCP_HTTP_BOOT` must be updated.

5. **Update remote server** — if deployed on VPS, re-run the install/update script or manually pull and run:
   ```bash
   cd /opt/tradeboard   # or wherever deployed
   git pull
   # Check .env for old OPENALGO_ vars and rename them
   ```

---

## Verification Checklist

Run these after rebranding to verify completeness:

```powershell
# Should return 0 results (except openalgo== pip package and uv.lock)
Select-String -Path "d:\Code\VS Code\tradeboard" -Pattern "openalgo" -Recurse -Include "*.py","*.md","*.yaml","*.yml","*.toml","*.sh","*.bat","*.ts","*.js","*.html","*.env" | Where-Object { $_.Line -notmatch "openalgo==" }

# Should return 0 results
Select-String -Path "d:\Code\VS Code\tradeboard" -Pattern "openalgo\.in" -Recurse -Include "*.py","*.md","*.ts","*.js"

# Should return 0 results  
Select-String -Path "d:\Code\VS Code\tradeboard" -Pattern "OPENALGO_" -Recurse -Include "*.py","*.sh","*.bat","*.ts"
```
