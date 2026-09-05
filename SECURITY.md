# Security Policy

## Scope

Chrome Secure is a local launcher-based authentication system for separating
Google Chrome profiles on Linux systems.

It provides an additional access-control layer before launching a selected
Chrome profile.

## Security Limitations

Chrome Secure is not a replacement for operating-system security or disk
encryption.

The protection is implemented at the launcher level. A user who already
controls the Linux account may potentially:

- Execute Chrome directly.
- Modify or replace the launcher.
- Access Chrome profile directories.
- Modify local configuration files.
- Use administrative/root privileges.

For stronger isolation, consider separate Linux user accounts and/or
encrypted storage.

## Password Storage

Passwords must never be stored in plaintext.

Chrome Secure uses password hashes rather than plaintext passwords.

Hash files must never be committed to a public Git repository.

## Reporting a Security Issue

Please avoid publicly disclosing sensitive vulnerabilities before they have
been investigated.

Contact the repository maintainer privately when possible.

## Never Commit

- Passwords
- Password hashes
- Cookies
- Browser sessions
- Browser history
- API keys
- Access tokens
- Private keys
- Personal Chrome profile data
- Backup copies containing personal data
