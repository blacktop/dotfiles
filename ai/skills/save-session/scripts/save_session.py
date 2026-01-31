#!/usr/bin/env python3
"""
Save AI agent session information for later resumption.

Supports Claude, Codex, Gemini, and other AI agents.
Stores session metadata in docs/.ai/sessions.json within the repository.
"""

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional


def load_sessions(sessions_file: Path) -> dict:
    """Load existing sessions or create empty structure."""
    if sessions_file.exists():
        with open(sessions_file, "r") as f:
            return json.load(f)
    return {"sessions": []}


def save_sessions(sessions_file: Path, data: dict) -> None:
    """Save sessions to file, creating parent directories if needed."""
    sessions_file.parent.mkdir(parents=True, exist_ok=True)
    with open(sessions_file, "w") as f:
        json.dump(data, f, indent=2)
        f.write("\n")


def add_session(
    sessions_file: Path,
    session_id: str,
    agent: str,
    summary: str,
    tags: Optional[list[str]] = None,
) -> None:
    """Add a new session to the sessions file."""
    data = load_sessions(sessions_file)

    # Check if session already exists
    for session in data["sessions"]:
        if session["id"] == session_id:
            # Update existing session
            session["summary"] = summary
            session["updated_at"] = datetime.now(timezone.utc).isoformat()
            if tags:
                session["tags"] = tags
            print(f"Updated existing session: {session_id}")
            save_sessions(sessions_file, data)
            return

    # Add new session
    new_session = {
        "id": session_id,
        "agent": agent,
        "summary": summary,
        "created_at": datetime.now(timezone.utc).isoformat(),
    }
    if tags:
        new_session["tags"] = tags

    data["sessions"].append(new_session)
    save_sessions(sessions_file, data)
    print(f"Saved session: {session_id}")


def main():
    parser = argparse.ArgumentParser(
        description="Save AI agent session information for later resumption"
    )
    parser.add_argument(
        "--session-id",
        required=True,
        help="Unique session identifier (UUID or agent-specific ID)",
    )
    parser.add_argument(
        "--agent",
        required=True,
        choices=["claude", "codex", "gemini", "copilot", "cursor", "aider", "chatgpt", "other"],
        help="AI agent type (claude, codex, gemini, copilot, cursor, aider, chatgpt, other)",
    )
    parser.add_argument(
        "--summary",
        required=True,
        help="Brief description of work done in this session",
    )
    parser.add_argument(
        "--tags",
        nargs="*",
        help="Optional tags for categorizing the session",
    )
    parser.add_argument(
        "--repo-root",
        default=os.getcwd(),
        help="Repository root directory (default: current directory)",
    )

    args = parser.parse_args()

    repo_root = Path(args.repo_root).resolve()
    sessions_file = repo_root / "docs" / ".ai" / "sessions.json"

    add_session(
        sessions_file=sessions_file,
        session_id=args.session_id,
        agent=args.agent,
        summary=args.summary,
        tags=args.tags,
    )

    print(f"Sessions file: {sessions_file}")


if __name__ == "__main__":
    main()
