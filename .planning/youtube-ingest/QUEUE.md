# YouTube ingest queue

> Videos shared with co-workers in the last 2 months.
> Process one at a time: fetch transcript → library entry → 4-step ingest → commit → next.
> Note: `UHVFcUzAGlM` appears twice (once with `&t=1166s` timestamp). Treat as one video.

| # | URL | Video ID | Status | Library slug |
|---|---|---|---|---|
| 1 | https://www.youtube.com/watch?v=2TLXsxkz0zI | `2TLXsxkz0zI` | done | `chris-parsons-ralph-loops` |
| 2 | https://www.youtube.com/watch?v=waFl4uBfXRA | `waFl4uBfXRA` | done | `mo-bitar-token-mania` |
| 3 | https://www.youtube.com/watch?v=kR64LOqBBCU | `kR64LOqBBCU` | done | `ido-salomon-agentcraft-orchestration` |
| 4 | https://www.youtube.com/watch?v=RjfbvDXpFls | `RjfbvDXpFls` | done | `mario-zechner-pi-world-of-slop` |
| 5 | https://www.youtube.com/watch?v=fdbXNWkpPMY | `fdbXNWkpPMY` | done | `lucas-meijer-love-letter-to-pi` |
| 6 | https://www.youtube.com/watch?v=WnzR5aOElvw | `WnzR5aOElvw` | pending | |
| 7 | https://www.youtube.com/watch?v=UHVFcUzAGlM | `UHVFcUzAGlM` | pending | |
| 8 | https://www.youtube.com/watch?v=JOA5x89MjRc | `JOA5x89MjRc` | pending | |
| 9 | https://www.youtube.com/watch?v=_Zcw_sVF6hU | `_Zcw_sVF6hU` | pending | |
| 10 | https://www.youtube.com/watch?v=bSG9wUYaHWU | `bSG9wUYaHWU` | pending | |
| 11 | https://www.youtube.com/watch?v=Fsh1NAuAXfc | `Fsh1NAuAXfc` | pending | |
| 12 | https://www.youtube.com/watch?v=L_9oU88UH_I | `L_9oU88UH_I` | pending | |
| 13 | https://www.youtube.com/watch?v=2Fmx-iHsKYg | `2Fmx-iHsKYg` | pending | |
| 14 | https://www.youtube.com/watch?v=UHVFcUzAGlM&t=1166s | duplicate of #7 | skip | |

---

## Watch history filtering (future work)

Ideas for auto-surfacing relevant videos from watch history:
- **Google Takeout** — export `watch-history.html` or JSON; parse video IDs + timestamps
- **YouTube Data API v3** — OAuth scope `youtube.readonly`; fetch `activities` or `playlistItems` for "Watch Later" / watch history playlist
- **MCP server** — wrap the API to let the agent query by channel ID or keyword
- Filter dimensions the user named:
  - Channel: specific channels of interest (AI Engineer, etc.)
  - Theme: physical fitness / modern work health; AI engineering; general engineering; philosophy; martial arts

See backlog for tracking this.
