# Chrome Secure Multi-Profile Authentication System

> A Fedora Linux project for adding a custom two-stage authentication layer and isolated Chrome profile environments.

**Platform:** Fedora Linux  
**Application:** Google Chrome (Flatpak)  
**Status:** Production / Active  
**Last updated:** 2026-09-05  

---

## ⚠️ Public Repository Safety

This repository should contain **documentation and sanitized source code only**.

**Never commit:**
- Password hashes (`*.hash`)
- Chrome profile data
- Cookies, sessions, browser databases, history, or bookmarks
- Backup copies of Chrome data
- Personal usernames, home-directory paths, account identifiers, or private configuration
- API keys, tokens, private keys, or other secrets

The examples in this README use generic profile names (`Profile 01`–`Profile 12`) and `$HOME` so the documentation can be published without exposing personal profile names or local usernames.

---

## 1. Executive Summary

This document describes a custom two-stage authentication and profile-isolation system built around Google Chrome on Fedora Linux.

The system was designed to provide the following workflow while keeping the Fedora desktop itself unlocked:

```text
Fedora desktop unlocked
        │
        ▼
   Click Chrome
        │
        ▼
 Master Chrome password
        │
        ▼
 Select one of 12 profiles
        │
        ▼
 Password for selected profile
        │
        ▼
 Open ONLY the selected isolated Chrome environment
```

The solution does **not** rely on Chrome's native profile switching as a security boundary. Instead, every Chrome profile is stored in its own Chrome `--user-data-dir`, and a custom launcher controls access to those environments.

The system is intended primarily to prevent casual or ordinary local access to the user's Chrome profiles. It is **not equivalent to Linux account isolation, filesystem encryption, or a hardware-backed password vault**.

---

## 2. Objectives

## 2.1 Primary objectives

The implementation was designed to:

- Require a master password before Chrome can be opened through the configured launcher.
- Display the available Chrome profiles only after the master password succeeds.
- Require a separate password for the selected profile.
- Open only the selected profile.
- Prevent the selected Chrome environment from presenting the other 11 profiles.
- Preserve existing profile data where possible, including tested Google sessions, extensions, history, and settings.
- Keep Fedora itself unlocked.
- Provide backups and a practical recovery path.
- Allow the complete system to be reverted.

## 2.2 Non-objectives

This system does not attempt to provide:

- Full-disk encryption.
- Protection against a user with root privileges.
- Protection against an attacker who can fully operate as the Fedora user.
- Guaranteed protection of Chrome data from direct filesystem access.
- Native Chrome profile encryption controlled by the custom profile passwords.
- Hardware-backed authentication.

---

# 3. Final User Experience

The intended normal workflow is:

1. Fedora is already unlocked.
2. The user clicks the pinned Chrome icon.
3. A **Chrome Master Password** dialog appears.
4. After successful verification, a list of 12 profiles appears.
5. The user selects a profile.
6. A password dialog for that specific profile appears.
7. If the password is correct, the isolated Chrome environment opens.
8. The other 11 profiles are not available inside that Chrome environment.

Example:

```text
Chrome Locked
Enter Chrome master password
             │
             ▼
       Chrome Profiles
             │
             ├── Profile 01
             ├── Profile 02
             ├── Profile 03
             ├── Profile 04
             ├── Profile 05
             ├── Profile 06
             ├── Profile 07
             ├── Profile 08
             ├── Profile 09
             ├── Profile 10
             ├── Profile 11
             └── Profile 12
                     │
                     ▼
            Profile password
                     │
                     ▼
          Selected isolated profile
```

---

# 4. Architecture

## 4.1 High-level architecture

```text
┌───────────────────────────────────────────────────────────┐
│                    Fedora Desktop                         │
│                    User already unlocked                  │
└─────────────────────────────┬─────────────────────────────┘
                              │
                              ▼
                  ┌─────────────────────┐
                  │  Chrome Desktop     │
                  │  Launcher (.desktop)│
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │    chrome-secure    │
                  │  Authentication     │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │ Master Password     │
                  └──────────┬──────────┘
                             │
                         SUCCESS
                             │
                             ▼
                  ┌─────────────────────┐
                  │ Profile Selector    │
                  └──────────┬──────────┘
                             │
                             ▼
                  ┌─────────────────────┐
                  │ Profile Password    │
                  └──────────┬──────────┘
                             │
                         SUCCESS
                             │
                             ▼
        ┌──────────────────────────────────────────┐
        │ Selected isolated Chrome user-data-dir  │
        └─────────────────────┬────────────────────┘
                              │
                              ▼
                   ┌────────────────────┐
                   │ Google Chrome      │
                   │ Flatpak            │
                   └────────────────────┘
```

---

# 5. Why Profile Isolation Was Necessary

Chrome profiles are useful for separating browsing data, but Chrome profile switching is not intended to be a strong security boundary.

The initial design used separate launchers for individual Chrome profiles while keeping the profiles inside the same Chrome user-data directory.

That design had a major weakness:

```text
Master password
      │
      ▼
Chrome opens
      │
      ▼
Chrome profile picker
      │
      ├── Profile A
      ├── Profile B
      ├── Profile C
      └── ...
```

A person could potentially switch to another profile from inside Chrome without going through the intended profile-specific password.

Therefore, the architecture was changed.

## Final design

Each profile received its own isolated Chrome data directory:

```text
--user-data-dir=/path/to/profile-environment
```

Each isolated environment contains only one Chrome profile.

Conceptually:

```text
Old architecture:

One Chrome user-data directory
        └── 12 Chrome profiles


Final architecture:

chrome-lock-profiles/
    ├── profile-01/
    │      └── one Chrome profile
    ├── profile-02/
    │      └── one Chrome profile
    ├── profile-03/
    │      └── one Chrome profile
    ├── ...
    └── profile-12/
           └── one Chrome profile
```

This is the central security improvement in the implementation.

---

# 6. Components

## 6.1 Secure launcher

Active launcher:

```text
~/.local/bin/chrome-secure
```

Responsibilities:

1. Validate configuration.
2. Check whether Chrome is already running.
3. Request the master password.
4. Verify the master password hash.
5. Display the 12-profile selector.
6. Determine the isolated environment for the selected profile.
7. Request the selected profile's password.
8. Verify the profile password hash.
9. Launch Chrome using that profile's isolated `--user-data-dir`.

---

## 6.2 Master password hash

Location:

```text
~/.config/chrome-lock/password.hash
```

The plaintext master password is not stored in this file.

The launcher derives a SHA-512 crypt-style hash using the salt contained in the stored hash and compares the result with the stored value.

---

## 6.3 Profile password hashes

Locations:

```text
~/.config/chrome-lock/
```

Files:

```text
profile-02.hash
profile-11.hash
profile-01.hash
profile-05.hash
profile-06.hash
profile-07.hash
profile-08.hash
profile-03.hash
profile-09.hash
profile-10.hash
profile-12.hash
profile-04.hash
```

Each profile has its own hash.

---

# 7. Profile Inventory

| # | Profile | Original Chrome directory | Isolated environment | Hash |
|---:|---|---|---|---|
| 1 | Profile 01 | `Default` | `profile-01` | `profile-01.hash` |
| 2 | Profile 02 | `Profile 2` | `profile-02` | `profile-02.hash` |
| 3 | Profile 03 | `Profile 3` | `profile-03` | `profile-03.hash` |
| 4 | Profile 04 | `Profile 5` | `profile-04` | `profile-04.hash` |
| 5 | Profile 05 | `Profile 6` | `profile-05` | `profile-05.hash` |
| 6 | Profile 06 | `Profile 7` | `profile-06` | `profile-06.hash` |
| 7 | Profile 07 | `Profile 8` | `profile-07` | `profile-07.hash` |
| 8 | Profile 08 | `Profile 9` | `profile-08` | `profile-08.hash` |
| 9 | Profile 09 | `Profile 10` | `profile-09` | `profile-09.hash` |
| 10 | Profile 10 | `Profile 11` | `profile-10` | `profile-10.hash` |
| 11 | Profile 11 | `Profile 12` | `profile-11` | `profile-11.hash` |
| 12 | Profile 12 | `Profile 13` | `profile-12` | `profile-12.hash` |

---

# 8. Directory Structure

## 8.1 Active configuration

```text
~/.config/chrome-lock/
├── password.hash
├── profile-02.hash
├── profile-11.hash
├── profile-01.hash
├── profile-05.hash
├── profile-06.hash
├── profile-07.hash
├── profile-08.hash
├── profile-03.hash
├── profile-09.hash
├── profile-10.hash
├── profile-12.hash
└── profile-04.hash
```

## 8.2 Active launcher

```text
~/.local/bin/
└── chrome-secure
```

A backup of the secure launcher was also created:

```text
~/.local/bin/chrome-secure.backup
```

## 8.3 Isolated Chrome environments

```text
~/.var/app/com.google.Chrome/config/chrome-lock-profiles/
├── profile-02/
├── profile-11/
├── profile-05/
├── profile-01/
├── profile-06/
├── profile-07/
├── profile-08/
├── profile-03/
├── profile-09/
├── profile-10/
├── profile-12/
└── profile-04/
```

Each directory represents one isolated Chrome environment.

## 8.4 Original Chrome data

```text
~/.var/app/com.google.Chrome/config/google-chrome/
```

This is the original Chrome data location.

It was intentionally not blindly deleted during migration.

---

# 9. Backup Locations

Backups created during the implementation included:

```text
~/.var/app/com.google.Chrome/config/google-chrome-backup
```

and:

```text
~/.var/app/com.google.Chrome/config/google-chrome-before-lock
```

A configuration backup was also created:

```text
~/.config/chrome-lock-backup/
```

It contained copies of the password hashes and launcher-related configuration.

The backup strategy was deliberately used before significant modifications.

---

# 10. Password System

## 10.1 Master password

The master password protects entry into the profile-selection stage.

```text
Master password
      │
      ▼
SHA-512 crypt-style hash
      │
      ▼
Compare with password.hash
```

## 10.2 Profile password

After profile selection:

```text
Profile password
      │
      ▼
Profile-specific hash
      │
      ▼
Compare with selected .hash file
```

A successful master password does **not** automatically satisfy the selected profile password.

---

# 11. File Permissions

The password hash files were configured with restrictive permissions.

Expected permission for hashes:

```text
600
```

The launcher was also intended to be executable and restricted to the user.

Check:

```bash
ls -l ~/.config/chrome-lock/*.hash
ls -l ~/.local/bin/chrome-secure
```

The important principle is that password hashes should not be world-readable.

---

# 12. Final Launcher Logic

The current launcher performs these operations:

```text
START
 │
 ├─ Check master hash exists
 │
 ├─ Check isolated profile directory exists
 │
 ├─ Check whether Chrome is already running
 │
 ├─ Ask for master password
 │
 ├─ Verify master password
 │
 ├─ Show 12 profiles
 │
 ├─ Determine selected profile
 │
 ├─ Check selected profile directory
 │
 ├─ Check selected profile hash
 │
 ├─ Ask for selected profile password
 │
 ├─ Verify profile password
 │
 └─ Launch:
       flatpak run com.google.Chrome
       --user-data-dir=<selected isolated directory>
```

---

# 13. Chrome Process Protection

The launcher checks for an existing Chrome process.

If Chrome is already running, the launcher refuses to open another isolated profile.

The reason is to avoid Chrome's normal process/session behavior causing a new invocation to interact with an already-running Chrome instance.

Recommended behavior:

```text
Chrome already running
        │
        ▼
Close Chrome completely
        │
        ▼
Run secure launcher again
```

To close the Flatpak Chrome instance:

```bash
flatpak kill com.google.Chrome
```

Use this only when you are comfortable closing Chrome and any unsaved browser state.

---

# 14. Desktop Launcher Integration

The active desktop launcher is:

```text
~/.local/share/applications/com.google.Chrome.desktop
```

The relevant entries currently point to:

```text
$HOME/.local/bin/chrome-secure
```

The normal launcher is:

```text
Exec=$HOME/.local/bin/chrome-secure %U
```

The New Window action is:

```text
Exec=$HOME/.local/bin/chrome-secure
```

The Incognito action is:

```text
Exec=$HOME/.local/bin/chrome-secure --incognito
```

The normal pinned-icon workflow has been tested successfully.

---

# 15. Incognito Behavior

The current configuration does not require the additional password behavior specifically for the Incognito action.

This was an intentional user decision.

The core profile-security workflow is therefore the normal Chrome launcher:

```text
Master password
      ↓
Profile selection
      ↓
Profile password
      ↓
Selected isolated profile
```

The Incognito behavior should not be considered part of the core two-stage profile-lock guarantee.

---

# 16. Initial Implementation and Why It Changed

## Stage 1 — Master launcher

A custom `chrome-lock` launcher was created.

Purpose:

```text
Password
   ↓
Chrome
```

This successfully demonstrated launcher-level password protection.

## Stage 2 — Per-profile launchers

Separate desktop files were temporarily created for each profile.

This was later rejected because all profiles still belonged to the same Chrome user-data environment.

## Stage 3 — Isolated environments

Each profile was copied into a separate environment and the copied `Local State` was modified so that only that profile was known to the isolated Chrome environment.

## Stage 4 — Migration testing

A dedicated migration environment was tested with the Profile 01 profile.

The following were verified:

- Existing Google login/session retained.
- Extensions retained.
- History retained.
- Profile appeared correctly.
- Only the intended profile was exposed.

The Profile 02 profile was separately tested and confirmed to work correctly.

## Stage 5 — All 12 environments

All 12 profiles were migrated into:

```text
chrome-lock-profiles/
```

## Stage 6 — Final launcher

`chrome-secure` was created to dynamically:

- authenticate the master password,
- select a profile,
- authenticate its profile password,
- launch only the corresponding isolated environment.

## Stage 7 — Desktop integration

The Fedora Chrome launcher was modified to invoke `chrome-secure`.

## Stage 8 — Cleanup

Temporary profile launchers and the old generic profile-lock script were removed.

---

# 17. Removed / Legacy Components

The following temporary launchers were removed:

```text
~/.local/share/applications/chrome-*-locked.desktop
```

The old generic profile launcher was removed:

```text
~/.local/bin/chrome-profile-lock
```

Additional old desktop launchers removed included:

```text
chrome-hnpfjngllnobngcgfapefoaidbinmjnm-Profile_2.desktop
google-chrome-locked.desktop
```

Do not recreate these unless intentionally rebuilding the old architecture.

---

# 18. Normal Operation

## Start Chrome

Use the pinned Chrome icon.

Expected sequence:

```text
Master password
      ↓
Profile selection
      ↓
Profile password
      ↓
Chrome
```

## Do not launch the wrong Chrome environment manually

The intended entry point is:

```text
chrome-secure
```

rather than directly launching an arbitrary Chrome environment.

---

# 19. Verification Tests

The implementation was tested with the following scenarios.

| Test | Expected result | Status |
|---|---|---|
| Correct master password | Continue to profile selector | Passed |
| Wrong master password | Access denied | Passed |
| Select valid profile | Ask for profile password | Passed |
| Correct profile password | Open selected profile | Passed |
| Wrong profile password | Access denied | Passed |
| Profile isolation | Other profiles unavailable in environment | Passed |
| Existing Google session | Retained during migration test | Passed |
| Existing extensions | Retained during migration test | Passed |
| Existing history | Retained during migration test | Passed |
| Chrome already running | Launcher refuses second environment | Implemented |
| Pinned Chrome icon | Two-stage flow | Passed |
| Incognito action | User accepted current behavior | Accepted |

---

# 20. Troubleshooting

## 20.1 Chrome does not open

First check whether Chrome is already running:

```bash
pgrep -af 'chrome|google-chrome'
```

If Chrome is running and you want to close it:

```bash
flatpak kill com.google.Chrome
```

Then try the pinned Chrome icon again.

---

## 20.2 Password dialog does not appear

Check the launcher:

```bash
ls -l ~/.local/bin/chrome-secure
```

Then test it directly:

```bash
~/.local/bin/chrome-secure
```

If the dialog appears when launched directly, the problem is probably the desktop launcher integration rather than the authentication script.

Check:

```bash
grep -n '^Exec=' ~/.local/share/applications/com.google.Chrome.desktop
```

Expected secure launcher entries contain:

```text
$HOME/.local/bin/chrome-secure
```

---

## 20.3 Master password is always rejected

Check that the hash exists:

```bash
ls -l ~/.config/chrome-lock/password.hash
```

Do not delete it.

If it is missing, restore it from:

```text
~/.config/chrome-lock-backup/
```

If the hash exists but the original password has genuinely been forgotten, see the password recovery section below.

---

## 20.4 One profile password is always rejected

Check the relevant hash:

```bash
ls -l ~/.config/chrome-lock/<profile>.hash
```

Example:

```bash
ls -l ~/.config/chrome-lock/profile-02.hash
```

Do not overwrite a working hash unless you intentionally want to reset that profile password.

---

## 20.5 A profile does not appear

Check:

```bash
ls -lah ~/.var/app/com.google.Chrome/config/chrome-lock-profiles/
```

Then check the relevant directory.

Example:

```bash
ls -lah ~/.var/app/com.google.Chrome/config/chrome-lock-profiles/profile-02/
```

If the directory is missing, do not recreate it by guessing or by copying random Chrome files.

Use the backup/recovery procedures.

---

## 20.6 Chrome opens the wrong profile

Do not immediately delete anything.

Check the mapping in:

```bash
~/.local/bin/chrome-secure
```

The mapping should associate each display name with the correct isolated directory.

Also verify the corresponding directory exists.

---

## 20.7 Chrome says another instance is running

Close Chrome:

```bash
flatpak kill com.google.Chrome
```

Wait a few seconds and retry.

If necessary:

```bash
pgrep -af 'chrome|google-chrome'
```

---

## 20.8 Application menu still shows old Chrome entries

Refresh:

```bash
update-desktop-database ~/.local/share/applications 2>/profile-08/null
```

Then log out and back in if the desktop environment has cached an old launcher.

---

# 21. Forgotten Master Password

This section is important.

## 21.1 Can the original password be recovered from `password.hash`?

Normally, the hash file does not provide a practical way to display the original plaintext password.

The correct distinction is:

```text
Password recovery ≠ password reset
```

If the original password is genuinely forgotten, the practical administrative solution is to **reset the password hash**.

However, anyone who can reset the hash from the same Fedora account is already operating with filesystem access to the account. Therefore, password reset is an administrative recovery operation, not protection against a person who already controls the Fedora account.

---

# 22. Resetting the Master Password

Before changing anything, make a backup:

```bash
mkdir -p ~/.config/chrome-lock-backup-before-password-reset
cp -a ~/.config/chrome-lock/password.hash \
      ~/.config/chrome-lock-backup-before-password-reset/
```

Generate a new SHA-512 password hash interactively:

```bash
openssl passwd -6
```

Enter the new password when prompted.

Copy the resulting complete hash.

Then replace the master hash:

```bash
nano ~/.config/chrome-lock/password.hash
```

Paste the new hash as the only line.

Save and exit.

Set permissions:

```bash
chmod 600 ~/.config/chrome-lock/password.hash
```

Test:

```bash
~/.local/bin/chrome-secure
```

The new master password should work.

**Important:** This changes only the master password. The 12 profile passwords remain unchanged.

---

# 23. Resetting a Profile Password

Example: resetting the `Profile 02` password.

Generate a new hash:

```bash
openssl passwd -6
```

Enter the new Profile 02 password.

Then:

```bash
nano ~/.config/chrome-lock/profile-02.hash
```

Replace the old hash with the new complete hash.

Set permissions:

```bash
chmod 600 ~/.config/chrome-lock/profile-02.hash
```

Repeat the same process for another profile using its corresponding hash file.

Examples:

```text
profile-01.hash
profile-03.hash
profile-04.hash
profile-07.hash
profile-08.hash
profile-09.hash
```

Only the selected profile's password changes.

---

# 24. If a Password Hash Is Accidentally Deleted

Do not recreate the file immediately if you have a known-good backup.

First:

```bash
ls -lah ~/.config/chrome-lock-backup/
```

Then restore the appropriate file.

Example:

```bash
cp ~/.config/chrome-lock-backup/profile-02.hash \
   ~/.config/chrome-lock/profile-02.hash
```

Then:

```bash
chmod 600 ~/.config/chrome-lock/profile-02.hash
```

For the master password:

```bash
cp ~/.config/chrome-lock-backup/password.hash \
   ~/.config/chrome-lock/password.hash

chmod 600 ~/.config/chrome-lock/password.hash
```

Only use the backup if it represents the password version you expect.

---

# 25. If `chrome-secure` Is Deleted or Broken

Check whether the backup exists:

```bash
ls -l ~/.local/bin/chrome-secure.backup
```

Restore it:

```bash
cp ~/.local/bin/chrome-secure.backup \
   ~/.local/bin/chrome-secure
```

Then:

```bash
chmod 700 ~/.local/bin/chrome-secure
```

Test:

```bash
~/.local/bin/chrome-secure
```

If the backup itself is unavailable, the configuration backup should be checked:

```bash
ls -lah ~/.config/chrome-lock-backup/
```

---

# 26. Emergency Access to Chrome

If the secure launcher is broken but you urgently need access to your Chrome data, do **not** delete the Chrome directories.

The Flatpak can be started directly:

```bash
flatpak run com.google.Chrome
```

This is an emergency administrative path.

It is also one of the reasons this system should not be described as a complete OS-level security boundary.

---

# 27. Complete Restore of Original Chrome Data

If the isolated environments become corrupted and you need to recover from the original Chrome data, first stop Chrome:

```bash
flatpak kill com.google.Chrome 2>/profile-08/null
```

Then preserve the current state before changing anything:

```bash
mv ~/.var/app/com.google.Chrome/config/chrome-lock-profiles \
   ~/.var/app/com.google.Chrome/config/chrome-lock-profiles-broken-$(date +%Y%m%d-%H%M%S)
```

Do **not** immediately overwrite `google-chrome`.

The original data should be preserved and inspected first.

The earlier backup locations are:

```text
google-chrome-backup
google-chrome-before-lock
```

Because Chrome profile migration involves shared `Local State` and profile-specific data, restoration should be performed deliberately rather than by copying arbitrary folders into each other.

---

# 28. Complete Revert of the Custom Security Layer

If you want to stop using the custom security system entirely, the safest principle is:

```text
1. Close Chrome
2. Preserve backups
3. Remove the local desktop override
4. Let the Flatpak desktop launcher be used again
5. Preserve or separately remove isolated data only after verifying Chrome
```

First:

```bash
flatpak kill com.google.Chrome 2>/profile-08/null
```

Preserve the current desktop launcher:

```bash
cp ~/.local/share/applications/com.google.Chrome.desktop \
   ~/.local/share/applications/com.google.Chrome.desktop.secure-final-backup
```

Remove the local desktop override:

```bash
rm -f ~/.local/share/applications/com.google.Chrome.desktop
```

Refresh:

```bash
update-desktop-database ~/.local/share/applications 2>/profile-08/null
```

The system should then fall back to the Flatpak-provided Chrome desktop entry.

If the native launcher does not appear immediately, log out and back in.

**Do not delete the isolated profile data yet.**

Verify normal Chrome operation first.

---

# 29. Removing the Isolated Profile Copies

Only after confirming that the required data is safely available elsewhere should the isolated copies be removed.

The isolated data is located at:

```text
~/.var/app/com.google.Chrome/config/chrome-lock-profiles/
```

Before deleting anything, inspect its size:

```bash
du -h -d 1 \
~/.var/app/com.google.Chrome/config/chrome-lock-profiles/ 2>/profile-08/null
```

For additional safety, make an archive or backup before deletion.

Do not run a recursive deletion command until you have confirmed that the isolated copies are no longer required.

---

# 30. Removing the Authentication Configuration

After the system has been successfully reverted and the backups are no longer needed, the authentication configuration can be removed:

```text
~/.config/chrome-lock/
~/.local/bin/chrome-secure
```

However, deleting these files is **not required** merely to stop using the secure launcher.

Keeping them as a recovery reference is often safer.

---

# 31. Security Threat Model

## 31.1 Threat: Casual person clicking Chrome

### Result

Protected.

They encounter:

```text
Master password
```

and cannot continue without it.

**Assessment:** Strong for the intended use case.

---

## 31.2 Threat: Person knows the master password but not a profile password

### Result

They can reach the profile selector but cannot open a selected profile without that profile's password.

**Assessment:** Protected.

---

## 31.3 Threat: Person knows one profile password

Knowing one profile password does not automatically provide the other profile passwords.

**Assessment:** Protected at the launcher level.

---

## 31.4 Threat: Person directly launches Chrome

A technically knowledgeable person with access to the Fedora user account can potentially bypass the custom launcher by launching the Flatpak directly.

**Assessment:** Not fully protected.

---

## 31.5 Threat: Person directly accesses Chrome files

The custom passwords are not used as encryption keys for the complete Chrome directories.

A person with sufficient access to the Fedora account can potentially inspect or copy files.

**Assessment:** Not protected at the filesystem level.

---

## 31.6 Threat: Root access

A root user can generally access files belonging to ordinary users.

**Assessment:** Not protected.

---

## 31.7 Threat: Offline disk access

This is primarily a Fedora/disk-encryption security problem rather than a Chrome launcher problem.

**Assessment:** Outside the scope of this launcher.

---

# 32. Security Rating

A practical assessment for the intended use case:

| Threat | Assessment |
|---|---|
| Casual local access | High protection |
| Wrong master password | High protection |
| Wrong profile password | High protection |
| Chrome profile switching | Strongly reduced through isolation |
| Direct Chrome execution | Not fully protected |
| Direct filesystem access | Not protected |
| Fedora root access | Not protected |
| Offline attacker | Depends on disk encryption and OS security |

The system should therefore be described as:

> **A custom launcher-level authentication and Chrome profile-isolation system, not an OS-level security boundary.**

---

# 33. Why Separate Linux Users Would Be Stronger

For a stronger security boundary, separate Linux users could be used.

Conceptually:

```text
Fedora
│
├── User A
│     └── Chrome environment A
│
├── User B
│     └── Chrome environment B
│
└── User C
      └── Chrome environment C
```

Linux filesystem permissions then become part of the security model.

This is stronger than a shell launcher but less convenient.

The current system deliberately favors convenience because the requirement was to keep the Fedora desktop unlocked.

---

# 34. Future Hardening Options

Possible future improvements include:

1. Restrictive ownership and permissions on all configuration files.
2. Better protection of the launcher against accidental modification.
3. Linux user isolation.
4. Encrypted storage for especially sensitive Chrome environments.
5. Full-disk encryption.
6. Separate system accounts.
7. Additional policy controls to reduce Chrome profile-management features.

These should be considered optional enhancements rather than changes to the currently working configuration.

---

# 35. Backup and Maintenance Procedure

A good maintenance routine is:

```text
Before modifying:
    ↓
Close Chrome
    ↓
Back up configuration
    ↓
Back up affected Chrome data
    ↓
Make one change
    ↓
Test
    ↓
Only then continue
```

For configuration:

```bash
cp -a ~/.config/chrome-lock \
      ~/.config/chrome-lock-backup-$(date +%Y%m%d-%H%M%S)
```

For the secure launcher:

```bash
cp ~/.local/bin/chrome-secure \
   ~/.local/bin/chrome-secure.backup
```

For Chrome data, prefer a dedicated backup location and ensure sufficient free disk space before copying multi-gigabyte directories.

---

# 36. Maintenance Checklist

Periodically verify:

```bash
ls -l ~/.local/bin/chrome-secure
ls -l ~/.config/chrome-lock/*.hash
ls -lah ~/.var/app/com.google.Chrome/config/chrome-lock-profiles/
```

Verify the desktop launcher:

```bash
grep -n '^Exec=' \
~/.local/share/applications/com.google.Chrome.desktop
```

Refresh desktop metadata if the launcher was changed:

```bash
update-desktop-database ~/.local/share/applications 2>/profile-08/null
```

---

# 37. Important Safety Rules

## Rule 1 — Do not delete the original Chrome data casually

Do not run:

```bash
rm -rf ~/.var/app/com.google.Chrome/config/google-chrome
```

unless you have deliberately verified backups and understand the consequences.

## Rule 2 — Do not delete the isolated profiles casually

Do not run:

```bash
rm -rf ~/.var/app/com.google.Chrome/config/chrome-lock-profiles
```

without verifying that the data is no longer needed.

## Rule 3 — Do not expose password hashes

The `.hash` files should remain private.

## Rule 4 — Keep recovery backups

At minimum, retain:

- A known-good Chrome data backup.
- A known-good password-hash backup.
- A known-good `chrome-secure` backup.

## Rule 5 — Close Chrome before migrations or restoration

This reduces the chance of Chrome writing to a profile while files are being copied or restored.

---

# 38. Quick Recovery Reference

## Chrome is stuck

```bash
flatpak kill com.google.Chrome
```

Then retry the launcher.

## Secure launcher broken

```bash
cp ~/.local/bin/chrome-secure.backup \
   ~/.local/bin/chrome-secure

chmod 700 ~/.local/bin/chrome-secure
```

## Master hash missing

Restore:

```bash
cp ~/.config/chrome-lock-backup/password.hash \
   ~/.config/chrome-lock/password.hash

chmod 600 ~/.config/chrome-lock/password.hash
```

## Profile hash missing

Restore the corresponding `.hash` from the configuration backup.

## Forgot master password

Reset the master hash using:

```bash
openssl passwd -6
```

Then replace:

```text
~/.config/chrome-lock/password.hash
```

## Forgot a profile password

Reset the corresponding profile hash.

## Need emergency Chrome access

```bash
flatpak run com.google.Chrome
```

## Need to completely stop using the security layer

Close Chrome, preserve backups, remove the local desktop launcher override, refresh the desktop database, and verify normal Chrome operation before deleting isolated data.

---

# 39. Current System Inventory

| Component | Location | Status |
|---|---|---|
| Secure launcher | `~/.local/bin/chrome-secure` | **ACTIVE** |
| Secure launcher backup | `~/.local/bin/chrome-secure.backup` | BACKUP |
| Master hash | `~/.config/chrome-lock/password.hash` | **ACTIVE** |
| Profile hashes | `~/.config/chrome-lock/*.hash` | **ACTIVE** |
| Isolated profiles | `~/.var/app/com.google.Chrome/config/chrome-lock-profiles/` | **ACTIVE** |
| Chrome desktop launcher | `~/.local/share/applications/com.google.Chrome.desktop` | **ACTIVE** |
| Original Chrome data | `~/.var/app/com.google.Chrome/config/google-chrome/` | ORIGINAL DATA |
| Chrome data backup | `.../google-chrome-backup` | BACKUP |
| Pre-lock Chrome backup | `.../google-chrome-before-lock` | BACKUP |
| Configuration backup | `~/.config/chrome-lock-backup/` | BACKUP |
| `chrome-profile-lock` | `~/.local/bin/chrome-profile-lock` | REMOVED |
| `chrome-*-locked.desktop` | `~/.local/share/applications/` | REMOVED |

---

# 40. Rebuild-from-Scratch Outline

If the complete system ever needs to be rebuilt, the high-level process is:

```text
1. Install/verify Chrome Flatpak
2. Verify Zenity
3. Verify OpenSSL
4. Close Chrome
5. Back up original Chrome data
6. Back up authentication configuration
7. Identify all Chrome profiles
8. Create one isolated environment per profile
9. Copy each profile's data
10. Copy and adjust Local State for each environment
11. Create password hashes
12. Create chrome-secure
13. Test each environment independently
14. Integrate the desktop launcher
15. Test normal Chrome icon
16. Test wrong passwords
17. Test profile isolation
18. Remove temporary launchers
19. Create final backups
```

A rebuild should always be performed from verified backups rather than from memory.

---

# 41. Final Architecture Summary

The final system can be summarized as:

```text
                         FEDORA
                           │
                    Desktop unlocked
                           │
                           ▼
                  ┌─────────────────┐
                  │ Chrome launcher │
                  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ Master Password │
                  └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │ Profile Picker  │
                  └────────┬────────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
              ▼            ▼            ▼
          Profile A    Profile B    Profile C
              │            │            │
              ▼            ▼            ▼
          Password      Password      Password
              │            │            │
              ▼            ▼            ▼
        Isolated A    Isolated B    Isolated C
              │            │            │
              └────────────┼────────────┘
                           │
                           ▼
                    Google Chrome
                       Flatpak
```

The essential security property is:

```text
One Chrome launch
       ↓
One authenticated profile
       ↓
One isolated Chrome data directory
```

---

# 42. Final Conclusion

The implementation successfully transformed Chrome from a normal multi-profile setup into a custom two-stage authenticated launcher system.

The key design decision was **profile isolation**, not merely adding passwords to individual launchers.

The resulting system provides:

- One master password.
- Twelve independent profile passwords.
- A profile selector after master authentication.
- One isolated Chrome environment per profile.
- Existing profile data preserved through migration testing.
- A controlled Fedora desktop launcher.
- Backup and recovery procedures.
- A complete rollback path.
- A documented threat model and security limitations.

The system should be treated as a **convenience-focused local security layer**. It is effective against normal/casual access but should not be represented as equivalent to Linux user isolation or encrypted storage.

The most important security principle is:

> **The custom passwords protect the launcher; the Fedora account and filesystem remain the ultimate security boundary.**

---


# 43. Recommended GitHub Repository Layout

For a public repository, documentation alone is not the best long-term structure if the goal is to let another Fedora user reproduce the project.

A recommended layout is:

```text
chrome-secure/
├── README.md
├── LICENSE
├── .gitignore
├── scripts/
│   ├── install.sh
│   ├── chrome-secure.sh
│   ├── setup-passwords.sh
│   └── uninstall.sh
├── config/
│   └── desktop-entry.template
├── docs/
│   └── recovery.md
└── SECURITY.md
```

### What belongs in the repository

| File | Purpose |
|---|---|
| `README.md` | Main project documentation and quick start |
| `scripts/chrome-secure.sh` | Sanitized, reusable launcher implementation |
| `scripts/install.sh` | Installation/setup automation |
| `scripts/setup-passwords.sh` | Local password-hash setup; must never contain real passwords |
| `scripts/uninstall.sh` | Safe removal procedure |
| `config/desktop-entry.template` | Template for the local desktop launcher |
| `.gitignore` | Prevents hashes, local data, backups, and secrets from being committed |
| `SECURITY.md` | Security limitations and vulnerability reporting |
| `LICENSE` | Legal terms for reuse |
| `docs/recovery.md` | Optional detailed recovery/runbook documentation |

### What must stay outside Git

The following are **local machine state**, not source code:

```text
~/.config/chrome-lock/*.hash
~/.var/app/com.google.Chrome/config/chrome-lock-profiles/
~/.var/app/com.google.Chrome/config/google-chrome/
~/.var/app/com.google.Chrome/config/google-chrome-backup/
~/.var/app/com.google.Chrome/config/google-chrome-before-lock/
```

Do not commit these directories.


# Appendix A — Useful Commands

### Check Chrome version

```bash
flatpak run com.google.Chrome --version
```

### Check Zenity

```bash
zenity --version
```

### Check launcher

```bash
ls -l ~/.local/bin/chrome-secure
```

### Test launcher directly

```bash
~/.local/bin/chrome-secure
```

### Check Chrome process

```bash
pgrep -af 'chrome|google-chrome'
```

### Close Flatpak Chrome

```bash
flatpak kill com.google.Chrome
```

### Check password files

```bash
ls -lah ~/.config/chrome-lock/*.hash
```

### Check isolated environments

```bash
du -h -d 1 \
~/.var/app/com.google.Chrome/config/chrome-lock-profiles/ 2>/profile-08/null
```

### Check desktop launcher

```bash
grep -n '^Exec=' \
~/.local/share/applications/com.google.Chrome.desktop
```

### Refresh application database

```bash
update-desktop-database ~/.local/share/applications 2>/profile-08/null
```

### Emergency direct Chrome launch

```bash
flatpak run com.google.Chrome
```

---

# Appendix B — Operational Golden Rules

```text
┌─────────────────────────────────────────────────────────┐
│                    GOLDEN RULES                         │
├─────────────────────────────────────────────────────────┤
│ 1. Never delete original Chrome data without backups.  │
│ 2. Never delete isolated profiles casually.            │
│ 3. Keep password hashes private.                       │
│ 4. Close Chrome before migration/restoration.          │
│ 5. Back up before changing launcher/password files.    │
│ 6. Treat direct Flatpak launch as an admin bypass.     │
│ 7. Remember: launcher security is not OS security.     │
│ 8. Verify a backup before deleting the original.       │
└─────────────────────────────────────────────────────────┘
```

---

**End of document**
