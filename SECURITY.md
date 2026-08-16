# Security and public-repository hygiene

`omniroute-patched` is a public repository. Treat every tracked file, commit,
workflow log, issue, pull request, release note, and release asset as public.

## Never commit

- `.env` or runtime environment files;
- provider API keys, OAuth tokens, refresh tokens, cookies, or JWT secrets;
- SSH private keys or private certificates;
- VPS passwords or database contents;
- real public infrastructure IP addresses/hostnames used only for private operations;
- backups copied from a production installation;
- provider connection exports or local OmniRoute data directories.

CI/canary credentials committed to workflows must be obviously synthetic,
non-production values used only inside an isolated ephemeral test process.

## Deployment boundary

The repository may contain generic installer/rollback logic, paths, service names,
and loopback ports. It must not contain credentials required to access a real
server. GitHub Actions must not SSH into or automatically deploy to production.

Production runtime configuration stays on the server and is read from local
root/service-user protected files. A GitHub Release is only a build artifact;
publishing it is not deployment.

## Automated checks

`scripts/check-public-hygiene.sh` scans tracked files for secret filenames,
private-key markers, common token prefixes, and non-private IPv4 literals.
The check is deliberately conservative and should run before release work.

If a check must allow a literal value for a test, prefer an RFC-reserved example
address/name or a clearly synthetic token rather than weakening the check.

## If sensitive data is committed

1. Revoke/rotate the credential first. Removing a Git commit is not credential rotation.
2. Remove the value from the current tree.
3. Evaluate whether Git history, tags, release assets, workflow logs, caches, forks,
   or external mirrors also need cleanup.
4. Rewrite public history only as an explicit maintenance operation; it changes
   commit identities and can disrupt clones, tags, and open pull requests.
