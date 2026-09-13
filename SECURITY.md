# Security Policy

## Reporting a vulnerability

Please **do not** open a public issue for security problems.

Use GitHub's private vulnerability reporting on this repository
(**Security → Report a vulnerability**), or email the maintainer listed in the
repository profile. Expect an acknowledgement within 7 days.

## Scope

ALMFx runs with the credentials you give it, against your Microsoft 365 tenant.
In scope: credential handling, command/script injection, unsafe deserialization,
accidental secret logging, overly broad permission requests, dependency
vulnerabilities.

Out of scope: misconfiguration of your own tenant, and anything requiring
already-compromised admin credentials.

## Handling credentials

- ALMFx never persists credentials. VS Code extensions use `SecretStorage`;
  PowerShell relies on `PnP.PowerShell` connection objects.
- Prefer certificate-based app-only auth or interactive login over client secrets.
- If you find a secret committed to this repo, report it privately — do not open
  a PR that only removes it, as the history still contains it.
