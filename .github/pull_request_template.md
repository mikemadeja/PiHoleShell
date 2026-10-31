## What this changes

<!-- What does this PR do, and why? Link any related issue, e.g. "Fixes #123". -->

## How it was tested

<!-- Which tests did you run, and against which Pi-hole version? -->

## Checklist

- [ ] This PR targets `develop`, not `main`
- [ ] New or changed functions call the API through `Invoke-PiHoleApiRequest` and have comment-based help
- [ ] New functions are exported in both `PiHoleShell.psm1` and `PiHoleShell.psd1`
- [ ] Tests were added or updated, and they pass
- [ ] `Invoke-ScriptAnalyzer -Path .\PiHoleShell -Recurse` reports nothing
- [ ] README command reference regenerated with `tools/Update-ReadmeCommandReference.ps1`, if functions were added or renamed
