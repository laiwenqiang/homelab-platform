# Lessons

## Windows Codex bridge is not the execution host

Rule: When planning `vm-windows-dev-01`, treat Windows as a Codex bridge/control plane, not as the machine that reads repositories, runs Maven/tests, or edits Git worktrees.

Why: The intended flow is iPhone ChatGPT -> Windows Codex App -> SSH to Linux Codex execution host -> Linux performs code/build/test/Git work -> results return through Windows to iPhone.

How to apply: Plans, inventory wording, security rules, and validation should separate Windows bridge responsibilities from Linux execution-host responsibilities. Do not recommend WSL2/Docker Desktop/local Windows builds as the primary path unless the user explicitly changes the architecture.
