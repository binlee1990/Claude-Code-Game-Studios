# AGENTS.md

This file governs autonomous coding agents working in this repository.

## Tool Hygiene

- Do not run shell commands whose only purpose is to print progress markers, placeholders, self-talk, tool-selection notes, apologies, or internal uncertainty.
- Forbidden examples include `Write-Output "now call image_gen"`, `Write-Output "marker"`, `echo "switching tools"`, `echo "noop"`, and similar no-op status commands.
- Shell commands must inspect state, transform files, run builds/tests, validate outputs, or perform another concrete repository task.
- If a tool-selection mistake or hesitation occurs, do not externalize it through shell. Correct the next tool call directly.
- Progress updates belong in the assistant commentary channel, not in terminal commands.
- Before running any shell command, check that its stdout/stderr would be useful evidence for the task. If not, do not run it.

## Failure Handling

- If noisy no-op commands are produced, stop that pattern immediately, state the issue once to the user, and resume with concrete execution only.
- Repeated no-op shell commands are a harness violation, not an acceptable progress update.
