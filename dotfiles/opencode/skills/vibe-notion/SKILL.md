---
name: vibe-notion
description: Interact with Notion through the local vibe-notion CLI
allowed-tools: Bash(/home/mfo/.local/bin/vibe-notion:*), Bash(vibe-notion:*)
---

# Vibe Notion

Use the `vibe-notion` CLI for Notion access.

## Rules

- Do not claim that Notion access is unavailable just because `webfetch` cannot read a Notion page.
- Do not suggest the official Notion API unless the user explicitly wants bot/integration mode.
- Prefer the local CLI over scraping or raw HTTP requests.
- Use `/home/mfo/.local/bin/vibe-notion ...` by default.
- If the binary is later available in PATH, `vibe-notion ...` is equivalent.

## Quick checks

```bash
/home/mfo/.local/bin/vibe-notion workspace list --pretty
```

If the binary later becomes available in PATH, this shorter form is equivalent:

```bash
vibe-notion workspace list --pretty
```

## Common commands

```bash
/home/mfo/.local/bin/vibe-notion workspace list --pretty
/home/mfo/.local/bin/vibe-notion search "Roadmap" --workspace-id <workspace-id> --pretty
/home/mfo/.local/bin/vibe-notion page get <page-id> --workspace-id <workspace-id> --pretty
/home/mfo/.local/bin/vibe-notion database query <database-id> --workspace-id <workspace-id> --pretty
```

## Behavior

- For reading a Notion page or database, use `/home/mfo/.local/bin/vibe-notion`, not `webfetch`.
- If a workspace id is needed, get it with `workspace list` first.
- If the user asks for private Notion content available in their desktop session, `vibe-notion` is the correct tool.