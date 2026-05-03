# API Research Template

Use this template when creating API_RESEARCH.md in Step 1.

```markdown
# API Research: {Service Name}

**Research Date:** {YYYY-MM-DD}
**Documentation Version:** {version if available}

## Sources (with dates)

- Official docs: {URL} (accessed {date})
- SDK repository: {URL} (last updated {date})
- Additional references: {URLs with dates}

**All sources verified as 2024-2025 current.**

## Authentication

**Method:** {API Key / OAuth 2.0 / JWT / etc.}
**How to obtain:** {exact steps or URL}
**How to pass:** {Header: "Authorization: Bearer TOKEN" / Query param / etc.}

## Official SDK

**Exists:** {Yes/No}
**Package name:** {npm package / PyPI package}
**Version:** {latest version number}
**Install command:** {npm install X / pip install X}
**Documentation:** {SDK docs URL}

## Base URL

{https://api.service.com/v1}

## Required Endpoints

### Operation 1: {operation-name}

- **Endpoint:** `{METHOD} /path/to/endpoint`
- **Verified:** ✓ Confirmed in official docs
- **Parameters:**
  - `param1` (required): {type} - {description}
  - `param2` (optional): {type} - {description}
- **Response schema:**
  ```json
  {
    "field": "type",
    "nested": {"field": "type"}
  }
  ```
- **Official example:** {link to example in docs}

### Operation 2: {operation-name}

{Repeat for EVERY planned operation from Step 0}

## Rate Limits

- **Requests per minute:** {number}
- **Requests per hour:** {number}
- **Rate limit headers:** {X-RateLimit-Remaining, etc.}

## Current Implementation Patterns (2024-2025)

**Async/await:** {Yes - modern async/await patterns used}
**Error handling:** {Standard HTTP status codes / Custom error format}
**Pagination:** {Cursor-based / Offset-based / Page-based}
**Webhooks:** {Supported: Yes/No, webhook verification method}

## Notes

{Any important gotchas, deprecations, or special considerations}
```
