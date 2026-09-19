# Private customization

Optionally clone your private-skills repository beside dotfiles. Its layout is:

```text
private-skills/
  CLAUDE.md
  AGENTS.md
  skills/
    example/
      SKILL.md
```

`ai/setup.sh` rebuilds installed instructions from the public source followed by
the matching private Markdown file. Repeated runs do not duplicate the private
tail. Missing private files produce public-only instructions. This replaces
installed instruction files; edit their source files rather than deployed copies.

`ai/sync-skills.sh` links private skill folders into the shared user skill
directory. It skips a missing checkout with a clone reminder and rejects name
collisions. Private skill contents stay in the private checkout; edits and Git
updates are immediately visible through those links.

The sync records its own links in `~/.agents/skills/.private-skill-links/`.
It prunes deleted/renamed skills and repairs those links after a checkout move
when run with the new checkout path. It never replaces an unrelated link or
directory. Exact links from the previous installer are adopted on the first
sync; run that sync before relocating an older checkout. A missing checkout
is skipped without pruning its links. Keep an empty `skills/` directory when
deliberately removing all private skills.
Run one sync at a time; the helper does not maintain a persistent lock.

Symlinks expose the entire skill directory. Keep evaluation fixtures under
`private-skills/evals/<name>/`, outside `skills/`, and generated caches out of
the skill source trees. A public skill that requires a private skill also
belongs in the private repository; optional integrations must have a standalone
fallback.

To run only these local steps, without updating community skills or CLI tools:

```fish
sh ai/sync-instructions.sh
sh ai/sync-private-skills.sh
```

Both helpers and setup honor `PRIVATE_SKILLS_DIR` for an alternate checkout:

```fish
env PRIVATE_SKILLS_DIR=/path/to/private-skills sh ai/sync-instructions.sh
```

Keep private instruction files and skill content out of this repository.
