# Security

## Reporting a vulnerability

Please do not open a public issue for a security problem.

Report it privately, either way:

- on GitHub: **Security → Report a vulnerability** on this repository, or
- by email to klaus@vithanco.com.

Say what you found, how to reproduce it, and which version or commit you tried.
I aim to answer within seven days.

## Supported versions

Fixes go into the latest release.

## What is in scope

- The Swift wrappers and the C bridge in this repository.
- The prebuilt libraries (`Graphviz.xcframework`, `CGraphviz.artifactbundle`,
  `CGraphvizWasm.artifactbundle`): a binary that does not match its recorded
  checksum or the documented build, or a patch that introduces a flaw.

## What is not

Weaknesses in Graphviz itself. Report those to the Graphviz project and tell me
if they affect this package.
