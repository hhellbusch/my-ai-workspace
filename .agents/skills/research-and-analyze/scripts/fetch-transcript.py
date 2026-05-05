#!/usr/bin/env python3
"""
fetch-transcript.py — YouTube transcript fetcher for research and library workflows.

Fetches transcripts from YouTube videos and saves them as markdown files,
suitable for use in research workspaces or the personal reference library.

Usage:
    python3 fetch-transcript.py <youtube-url> <output-path>
    python3 fetch-transcript.py <youtube-url> <output-path> --lang en
    python3 fetch-transcript.py --batch <urls-file> <output-dir>

Where:
    <youtube-url>  — A YouTube video URL (any format)
    <output-path>  — Path for the output .md file, or directory for batch mode
    <urls-file>    — Text file with one YouTube URL per line (batch mode)

Dependencies:
    Required: youtube-transcript-api
    Install:  pip install youtube-transcript-api
"""

import sys
import re
import os
import time
import argparse
from pathlib import Path

try:
    from youtube_transcript_api import YouTubeTranscriptApi
    from youtube_transcript_api._errors import (
        TranscriptsDisabled,
        NoTranscriptFound,
        VideoUnavailable,
    )
except ImportError:
    print("Missing dependency. Install with:")
    print("  pip install youtube-transcript-api")
    sys.exit(1)

try:
    import requests
except ImportError:
    requests = None


def extract_video_id(url: str) -> str | None:
    """Extract video ID from various YouTube URL formats."""
    patterns = [
        r"(?:v=|/v/|youtu\.be/)([a-zA-Z0-9_-]{11})",
        r"^([a-zA-Z0-9_-]{11})$",
    ]
    for pattern in patterns:
        match = re.search(pattern, url)
        if match:
            return match.group(1)
    return None


def fetch_video_metadata(video_id: str) -> dict:
    """Fetch basic video metadata via oembed (no API key needed)."""
    if not requests:
        return {"title": f"Video {video_id}", "author": "Unknown"}

    try:
        url = f"https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v={video_id}&format=json"
        resp = requests.get(url, timeout=10)
        if resp.status_code == 200:
            data = resp.json()
            return {
                "title": data.get("title", f"Video {video_id}"),
                "author": data.get("author_name", "Unknown"),
            }
    except Exception:
        pass

    return {"title": f"Video {video_id}", "author": "Unknown"}


def fetch_transcript(video_id: str, lang: str = "en") -> tuple[list | None, str | None]:
    """Fetch transcript for a video. Returns (segments, error)."""
    try:
        ytt = YouTubeTranscriptApi()
        transcript = ytt.fetch(video_id, languages=[lang])
        segments = []
        for snippet in transcript:
            segments.append({
                "text": snippet.text,
                "start": snippet.start,
                "duration": snippet.duration,
            })
        return segments, None
    except TranscriptsDisabled:
        return None, "Transcripts are disabled for this video"
    except NoTranscriptFound:
        try:
            ytt = YouTubeTranscriptApi()
            transcript = ytt.fetch(video_id)
            segments = []
            for snippet in transcript:
                segments.append({
                    "text": snippet.text,
                    "start": snippet.start,
                    "duration": snippet.duration,
                })
            return segments, f"No '{lang}' transcript; used auto-detected language"
        except Exception as e:
            return None, f"No transcript found: {e}"
    except VideoUnavailable:
        return None, "Video is unavailable"
    except Exception as e:
        return None, f"Error: {e}"


def format_timestamp(seconds: float) -> str:
    """Convert seconds to HH:MM:SS or MM:SS format."""
    h = int(seconds // 3600)
    m = int((seconds % 3600) // 60)
    s = int(seconds % 60)
    if h > 0:
        return f"{h}:{m:02d}:{s:02d}"
    return f"{m}:{s:02d}"


def segments_to_markdown(segments: list, timestamps: bool = True) -> str:
    """Convert transcript segments to readable markdown text."""
    if not timestamps:
        return " ".join(seg["text"] for seg in segments)

    lines = []
    paragraph = []
    last_break = 0

    for seg in segments:
        paragraph.append(seg["text"])
        if seg["start"] - last_break >= 60 or seg["text"].rstrip().endswith((".", "?", "!")):
            ts = format_timestamp(last_break)
            text = " ".join(paragraph)
            lines.append(f"**[{ts}]** {text}")
            paragraph = []
            last_break = seg["start"]

    if paragraph:
        ts = format_timestamp(last_break)
        text = " ".join(paragraph)
        lines.append(f"**[{ts}]** {text}")

    return "\n\n".join(lines)


def save_transcript(video_id: str, metadata: dict, segments: list,
                    output_path: Path, note: str = None):
    """Save transcript as a markdown file."""
    url = f"https://www.youtube.com/watch?v={video_id}"
    title = metadata.get("title", f"Video {video_id}")
    author = metadata.get("author", "Unknown")

    duration_secs = 0
    if segments:
        last = segments[-1]
        duration_secs = last["start"] + last["duration"]
    duration_str = format_timestamp(duration_secs)

    header = f"# Transcript: {title}\n\n"
    header += f"- **Channel:** {author}\n"
    header += f"- **URL:** {url}\n"
    header += f"- **Duration:** {duration_str}\n"
    header += f"- **Fetched:** {time.strftime('%Y-%m-%d %H:%M:%S')}\n"
    header += f"- **Segments:** {len(segments)}\n"
    if note:
        header += f"- **Note:** {note}\n"
    header += "\n---\n\n"

    body = segments_to_markdown(segments)
    plain = "\n\n---\n\n## Plain Text\n\n"
    plain += " ".join(seg["text"] for seg in segments)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w") as f:
        f.write(header + body + plain)

    return len(segments)


def generate_filename(metadata: dict, video_id: str) -> str:
    """Generate a filesystem-safe filename from video metadata."""
    title = metadata.get("title", video_id)
    slug = re.sub(r"[^\w\s-]", "", title.lower())
    slug = re.sub(r"[\s_]+", "-", slug).strip("-")
    slug = slug[:80]
    return f"{slug}.md"


def main():
    parser = argparse.ArgumentParser(
        description="Fetch YouTube transcripts and save as markdown"
    )
    parser.add_argument("url", nargs="?", help="YouTube video URL")
    parser.add_argument("output", nargs="?", help="Output file path or directory")
    parser.add_argument(
        "--lang", default="en",
        help="Preferred transcript language (default: en)"
    )
    parser.add_argument(
        "--batch", metavar="FILE",
        help="Batch mode: text file with one YouTube URL per line"
    )
    parser.add_argument(
        "--no-timestamps", action="store_true",
        help="Output plain text without timestamps"
    )

    args = parser.parse_args()

    if args.batch:
        batch_file = Path(args.batch)
        if not batch_file.exists():
            print(f"Error: {batch_file} not found")
            sys.exit(1)

        output_dir = Path(args.output) if args.output else Path(".")
        output_dir.mkdir(parents=True, exist_ok=True)

        urls = [line.strip() for line in batch_file.read_text().splitlines() if line.strip() and not line.startswith("#")]
        print(f"Batch mode: {len(urls)} URLs")

        success = 0
        failed = 0
        for url in urls:
            video_id = extract_video_id(url)
            if not video_id:
                print(f"  SKIP: {url} (can't extract video ID)")
                failed += 1
                continue

            metadata = fetch_video_metadata(video_id)
            segments, error = fetch_transcript(video_id, args.lang)

            if not segments:
                print(f"  FAIL: {metadata['title']} — {error}")
                failed += 1
                continue

            filename = generate_filename(metadata, video_id)
            output_path = output_dir / filename
            count = save_transcript(video_id, metadata, segments, output_path, note=error)
            print(f"  OK: {metadata['title']} ({count} segments) → {output_path}")
            success += 1

        print(f"\nDone: {success} fetched, {failed} failed")

    else:
        if not args.url:
            parser.print_help()
            sys.exit(1)

        video_id = extract_video_id(args.url)
        if not video_id:
            print(f"Error: Can't extract video ID from '{args.url}'")
            sys.exit(1)

        print(f"Fetching metadata for {video_id}...")
        metadata = fetch_video_metadata(video_id)
        print(f"  Title: {metadata['title']}")
        print(f"  Channel: {metadata['author']}")

        print(f"Fetching transcript (lang={args.lang})...")
        segments, error = fetch_transcript(video_id, args.lang)

        if not segments:
            print(f"Error: {error}")
            sys.exit(1)

        if error:
            print(f"  Note: {error}")

        if args.output:
            output_path = Path(args.output)
        else:
            filename = generate_filename(metadata, video_id)
            output_path = Path(filename)

        if output_path.is_dir():
            filename = generate_filename(metadata, video_id)
            output_path = output_path / filename

        count = save_transcript(video_id, metadata, segments, output_path, note=error)
        print(f"Saved {count} segments to {output_path}")


if __name__ == "__main__":
    main()
