# Contributing to PiHoleShell

Thanks for helping out! Bug reports, feature requests, docs fixes and pull requests are all welcome.

## Reporting bugs and requesting features

Use the [issue forms](https://github.com/mikemadeja/PiHoleShell/issues/new/choose). For bugs, please include your PiHoleShell, PowerShell and Pi-hole versions, the command you ran, and the full error. Remove your server address and password first.

Found a security problem? Don't open a public issue. Follow the [security policy](SECURITY.md) instead.

## Branches and pull requests

- Branch from **`develop`** and open your pull request **into `develop`**. Never target `main`.
- `main` is the release branch. The maintainer promotes `develop` → `main`, and merging that PR publishes a new release automatically.
- Keep each PR to one feature or fix, and describe what changed and how you tested it.
- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `test:`, `refactor:`, `ci:` or `chore:`.

## Adding or changing a function

1. **Check the real API first.** Your Pi-hole serves its own API docs at `https://<your-pihole>/api/docs`. Confirm the endpoint's path, parameters and response fields there, not from similar functions.
2. **Put the function in its own file**, `PiHoleShell/Public/<Area>/<Verb>-PiHole<Noun>.ps1`, using an [approved verb](https://learn.microsoft.com/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands).
3. **Use the standard parameters:** `PiHoleServer`, `Password`, `IgnoreSsl` and, for functions that return data, `RawOutput`.
4. **Call the API through `Invoke-PiHoleApiRequest`.** This private helper handles login, the request and logout. Don't copy that block into your function: SonarCloud fails the build when more than 3% of new code is duplicated.
5. **Report errors through the friendly message helper:**

   ```powershell
   catch {
       Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
   }
   ```

6. **Write comment-based help** with `.SYNOPSIS`, `.DESCRIPTION`, every `.PARAMETER`, at least one `.EXAMPLE`, and a `HelpUri` pointing at the endpoint in Pi-hole's API docs.
7. **Export the function** in both places:
   - the `Export-ModuleMember` list in `PiHoleShell/PiHoleShell.psm1`
   - `FunctionsToExport` in `PiHoleShell/PiHoleShell.psd1`. This file is saved as UTF-16; keep that encoding when you edit it.
8. **Update the docs:**
   - Run `tools/Update-ReadmeCommandReference.ps1` to regenerate the README's command reference. A CI check fails if it's out of date.
   - Add an entry to `tools/Update-ExampleOutput.ps1`, then run it to regenerate `docs/EXAMPLES.md`. This step needs a test server.

`Get-PiHoleApiEndpoint` (`PiHoleShell/Public/FTLInformation/Get-PiHoleApiEndpoint.ps1`) is a short, complete example that follows all of these.

## Tests

Tests use [Pester 5](https://pester.dev/) and live under `tests/`, in the same area folders as the functions.

- **Unit tests** (`*.Tests.ps1`) mock the API and run anywhere:

  ```powershell
  Invoke-Pester -Path .\tests -ExcludeTagFilter Integration
  ```

- **Integration tests** (`*.Integration.Tests.ps1`) call a real Pi-hole. Copy `tests/IntegrationConfig.example.ps1` to `tests/IntegrationConfig.local.ps1` (it's gitignored) and fill in your server and app password. Then run:

  ```powershell
  Invoke-Pester -Path .\tests -TagFilter Integration
  ```

  Some integration tests make real changes, like rebuilding gravity, restarting DNS and flushing logs. Point them at a test instance, not your production Pi-hole.

New functions should come with an integration test covering normal output, `-RawOutput $true`, and a bad password.

## Checks on your pull request

- **PSScriptAnalyzer** must report no issues. Run it locally with `Invoke-ScriptAnalyzer -Path .\PiHoleShell -Recurse`.
- **SonarCloud** must pass its quality gate. In practice that usually means not duplicating code.
- **README sync** must pass (see step 8 above).
- **Pester** integration tests run against the maintainer's own Pi-hole and can take up to an hour. If your PR comes from a fork, the maintainer may run them for you.

## Code of conduct

Everyone taking part is expected to follow the [code of conduct](CODE_OF_CONDUCT.md).
