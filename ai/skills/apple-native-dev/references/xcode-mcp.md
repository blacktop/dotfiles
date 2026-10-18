# Headless Xcode through MCP

Use this workflow when Xcode's project model, previews, debugger, or simulator
interaction adds value. Preserve the user's chosen coding agent and account.
The selected Xcode and its advertised tool schemas are authoritative; tool names,
parameters, templates, and available destinations can change between releases.

## Select and connect

Read the selected toolchain's capabilities first:

```zsh
xcodebuild -version
xcrun --find mcpbridge
xcrun mcp-server --help
xcrun mcp-server status --format json
```

Headless service support arrived during Xcode 27. If the selected installation
lacks it, use the existing CLI workflow or an authorized Xcode UI session. With
multiple installations, set `DEVELOPER_DIR` for the bridge process, using the
chosen app's `Contents/Developer` path, rather than changing the host selection.

If enabling external access is part of the request, the user can run this in
their own terminal, where `sudo` can request an administrator password:

```fish
sudo xcrun mcp-server enable
```

The service starts when a client connects. Retain individual agent and folder
grants; do not add `--unsafe-always-allow-all-agents` as a convenience fix. Opening
or creating the first workspace may wait for the user's approval. Use `status`
to diagnose pending requests and granted folders; stop at a denied or pending
grant rather than repeatedly submitting the same operation. Permission resets,
broader grants, and host-wide settings changes need their own authorization.

Register the bridge in the client and scope the user chose. For Codex's user
configuration, run in the agent shell:

```zsh
codex mcp add xcode -- xcrun mcpbridge
```

For a shared Codex checkout, merge this into the trusted repository's
`.codex/config.toml` instead:

```toml
[mcp_servers.xcode]
command = "xcrun"
args = ["mcpbridge"]
```

For Claude Code, a project-scoped registration from the repository root is:

```zsh
claude mcp add --transport stdio --scope project xcode -- xcrun mcpbridge
```

That produces `.mcp.json`; merge with an existing registration instead of
replacing unrelated servers. Verify the chosen client's `mcp list` output, then
discover its exposed Xcode tools. `mcp-server` manages the service; `mcpbridge`
is the stdio transport. `xcrun agent <agent>` instead launches Xcode's managed
agent environment and may open the UI, so use it only when that environment is
actually wanted.

## Use Apple's current skills

When Apple's SwiftUI or device-interaction guidance would help, export from the
selected Xcode to an absolute project-local path. From the repository root:

```zsh
# Codex
xcrun agent skills export --output-dir "$PWD/.agents/skills"
# Claude Code: use this destination instead
xcrun agent skills export --output-dir "$PWD/.claude/skills"
```

Export can launch Xcode. Review the exported files and load only the relevant
skills, particularly `swiftui-specialist` and `device-interaction` when present.
Existing directories are preserved by default; use `--replace-existing` only
when intentionally refreshing an export after reviewing local changes.

## Open or create the project

For an existing project, use `XcodeOpenWorkspace` with its actual project or
workspace path, then retain the returned workspace identifier. Prefer a
workspace when it owns the project's dependencies. Discover schemes and run
destinations before selecting the ones required by the task.

For a new project, use `XcodeListTemplates` with `kind: "project"`, narrow by
filter or template identifier, and read the resulting option schema before
calling `XcodeNewProject`. Use an absolute parent directory for `destinationPath`
and check the returned project path before opening it. Do not guess template
identifiers, storage options, or test-system values. For an XcodeGen repository,
edit `project.yml` and regenerate through its existing commands instead.

Preserve the project's chosen configuration format. Xcode 27.2 can use a JSON
`.xcproj` configuration inside the `.xcodeproj` bundle; do not assume every
project contains `project.pbxproj` or migrate formats as a side effect.

## Verify the requested behavior

1. Select the intended scheme and destination, then use `BuildProject` or the
   repository's build command. Read diagnostics and the full log on failure.
   Run the relevant tests; a successful build alone does not establish behavior.
2. For UI work, render the meaningful states with `RenderPreview` and actually
   open the resulting images. Use named `#Preview(arguments:)` variants when the
   selected SDK supports them. Check relevant loading, empty, content, and
   failure states, plus appearance or text-size variants the task calls for.
3. For navigation, input, or state propagation, use the installed
   `device-interaction` guidance and current MCP schema. Open an interaction
   session, select or boot the requested simulator, and build, install, and
   launch the app. Capture the screen and accessibility hierarchy before
   acting. Find controls by their labels or identifiers and use fresh reported
   hit points instead of invented coordinates; recapture after transitions.
4. Verify the final visible result and the relevant state change. Use assertions,
   test results, or scoped `OSLog`/debugger output when a screenshot cannot prove
   it. Give unclear controls accessible labels in the app. Report the actual
   device, OS, scheme, and evidence collected, then close the interaction session
   to release its resources, including on failure.

For side-by-side review, an optional self-contained HTML artifact can embed
labeled preview PNGs with their device, OS, and appearance. Use the available
`html-artifacts` skill for that deliverable; otherwise report the image paths.
Keep build, test, preview, simulator, physical-device, and signing claims scoped
to what actually ran. This workflow does not itself authorize signing, uploading,
or deploying an app.

## Troubleshooting and sources

- If tools are unavailable, check the selected Xcode version, service status,
  client registration, and workspace approval. Older UI-backed configurations
  need an open project. For a service failure, `xcrun mcp-server show-logs` writes
  a diagnostic log and returns its path; inspect only what the issue needs.
- If UI automation misses a control, inspect a fresh accessibility hierarchy
  and the exported interaction syntax before retrying. Surface a missing runtime,
  unsupported tool, or permission blocker instead of silently changing devices.
- Apple's [external-agent setup](https://developer.apple.com/documentation/xcode/giving-external-agents-access-to-xcode),
  [Xcode 27 release notes](https://developer.apple.com/documentation/xcode-release-notes/xcode-27-release-notes),
  and [project configuration formats](https://developer.apple.com/documentation/xcode/updating-your-xcode-project-configuration-file-format).
- OpenAI's [MCP configuration](https://learn.chatgpt.com/docs/extend/mcp) and
  [skill discovery](https://learn.chatgpt.com/docs/build-skills).
- Workflow inspiration and example app:
  [Artem Novichkov's headless-Xcode walkthrough](https://artemnovichkov.com/blog/headless-xcode-from-prompt-to-simulator-with-mcp).
