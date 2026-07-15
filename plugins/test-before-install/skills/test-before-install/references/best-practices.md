# Test-before-install best practices (general supply-chain hygiene)

Distilled from widely-accepted software supply-chain guidance (OWASP, SLSA,
package-manager security advisories, "don't curl|bash" consensus). Apply the ones
relevant to the artifact; they complement the scanning workflow, not replace it.

## Before fetching
- **Check provenance & reputation.** Author, org, repo age, stars, open issues,
  release cadence, whether it's archived. A brand-new repo with no history that
  wants deep access is higher risk.
- **Watch for typosquatting / impersonation.** Confirm the exact org/user and name
  match what the user intended (`dannycohen/enhance`, not a look-alike).
- **Prefer a pinned ref.** Install a specific tag or commit you have reviewed, not
  a moving `main`. Record the ref in the report.

## While reviewing
- **Read before you run.** Never execute an installer you haven't read. Reject
  `curl … | bash` / `iwr … | iex` install instructions — fetch, read, then run.
- **Assume install-time code runs.** Package `postinstall`, plugin hooks, and
  `SessionStart`/`PreToolUse` hooks execute on install/load, before you "use"
  anything. Review them first.
- **Least privilege.** Ask what the artifact actually needs (network? filesystem?
  credentials? which tools?) and treat anything beyond that as suspect.
- **Verify signatures/checksums** when the publisher provides them.
- **Diff forks against upstream.** For a fork, diff the executable/hook/manifest
  surface against the original; scrutinize what diverges.

## Isolation
- **Static first, dynamic only when sandboxed.** Static analysis and reading are
  safe. Anything that executes the artifact belongs in a throwaway config dir
  (see scanning-tools.md), a container, or a VM — never your real environment.
- **Keep the real config untouched** until the verdict is made and the user
  approves. Scan copies in quarantine, not the live install path.

## Decision & after install
- **Informed consent over pass/fail.** Deliver a verdict plus the concrete side
  effects (see triage.md), so the user approves knowing what it does.
- **Install the exact reviewed ref**, then re-verify what landed matches quarantine.
- **Re-scan on update.** A safe v1 does not make v2 safe; re-run this process when
  the artifact updates or you move to a new commit.
