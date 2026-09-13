---
name: pnp-reference
description: Use before writing or reviewing any PnP.PowerShell, CLI for Microsoft 365, or SPFx toolchain command in this repo. Verifies a cmdlet, parameter, or CLI flag actually exists instead of guessing. Trigger on any Add-PnP*, Get-PnP*, Publish-PnP*, m365 spo *, gulp bundle/package-solution, or "does this cmdlet exist" question.
---

# Verifying PnP / SPFx commands

**Read [`docs/reference/spfx-alm/cmdlets.md`](../../../docs/reference/spfx-alm/cmdlets.md)
now.** It holds the verification method, the verified cmdlet list, verbatim
signatures, and every cross-cutting fact (`--ship`, version bumping,
`-SkipFeatureDeployment`, connections in v3, the shared service principal).

This skill deliberately does not repeat any of that. One copy, in the reference,
is the whole point — a second copy here would drift and you would have no way to
tell which one was stale.

## Why this skill exists

Cmdlet hallucination is the dominant failure mode in this domain. PnP.PowerShell
has ~900 cmdlets with highly regular names, so an invented one looks exactly like
a real one. The cost is asymmetric: a wrong cmdlet in a skill or a function's
help gets copied into someone's production tenant script.

## What to do

1. Read the reference page above.
2. If the command you need is not on its verified list, verify it yourself using
   the method that page describes — do not assume it exists because the name
   looks right.
3. If you verified a new cmdlet, **add it to
   `docs/reference/spfx-alm/cmdlets.md`** and update the verification date at the
   top. Do not record it in the file you happened to be editing.

## Reviewing someone else's code

Treat every PnP cmdlet, parameter name, and CLI flag in a diff as unverified
until checked. `-Scope` vs `-SiteUrl` vs `-Site` differ between cmdlets in the
same family, and a plausible-looking parameter is as damaging as a fake cmdlet.

Flag anything you could not verify rather than letting it through on the grounds
that it reads correctly.
