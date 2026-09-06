# Chrome Secure 🔐

> A two-stage password-protected launcher for isolated Google Chrome profiles on Fedora Linux.

**Chrome Secure** is a lightweight security layer for Linux users who want to protect access to multiple Google Chrome profiles with separate passwords.

Instead of allowing Chrome to open directly and exposing all configured profiles, Chrome Secure places an authentication layer in front of Chrome.

The user must:

1. Enter the **Master Password**
2. Select a Chrome profile
3. Enter the **password for that profile**
4. Open only the authenticated profile

Each protected profile is launched using its own isolated Chrome data directory.

---

## 🔐 How It Works

```text
                    Click Chrome
                         │
                         ▼
                 ┌─────────────────┐
                 │ Master Password │
                 └────────┬────────┘
                          │
                    ✓ Verified
                          │
                          ▼
                 ┌─────────────────┐
                 │ Select Profile  │
                 └────────┬────────┘
                          │
                          ▼
                 ┌─────────────────┐
                 │ Profile Password│
                 └────────┬────────┘
                          │
                    ✓ Verified
                          │
                          ▼
              ┌───────────────────────┐
              │ Isolated Chrome       │
              │ Profile Environment   │
              └───────────────────────┘
```

### Two Levels of Authentication

#### 1. Master Password

The **Master Password** is the first authentication layer.

It must be successfully verified before the user can access the profile selection screen.

```text
Chrome Launcher
      ↓
Master Password
      ↓
Authentication
      ↓
Profile Selector
```

#### 2. Profile Password

After the master password is verified, the user selects the Chrome profile they want to open.

Each profile has its own password.

```text
Select Profile
      ↓
Profile Password
      ↓
Authentication
      ↓
Open Selected Profile
```

If either authentication step fails, the selected Chrome profile is not launched.

---

## 🧩 Profile Isolation

Chrome Secure uses Chrome's `--user-data-dir` mechanism to create separate Chrome environments for each protected profile.

Conceptually:

```text
                    Chrome Secure
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
     Profile 01     Profile 02     Profile 03
          │              │              │
      Password       Password       Password
          │              │              │
          ▼              ▼              ▼
    Isolated Data   Isolated Data   Isolated Data
          │              │              │
          ▼              ▼              ▼
       Chrome          Chrome          Chrome
```

The same architecture can be used for additional profiles.

When a profile is launched, Chrome receives only the isolated data directory assigned to that profile.

This helps prevent the normal Chrome profile-selection interface from exposing the other protected environments.

### One Launch = One Profile

The core design principle is:

```text
One Launch
    ↓
One Authentication
    ↓
One Selected Profile
    ↓
One Isolated Chrome Data Directory
```

---

## ✨ Features

- 🔐 Master password authentication
- 🔑 Individual password for each Chrome profile
- 👤 Graphical profile selection
- 🧩 Isolated Chrome data directories
- 🚫 Prevents normal profile switching inside the isolated environment
- 💾 Supports migration of existing Chrome profile data
- 🖥️ Designed for Fedora Linux
- 📦 Supports Google Chrome installed through Flatpak
- 🛠️ Bash-based implementation
- 🔄 Backup and recovery procedures
- 📚 Detailed technical documentation
- 🛡️ Security limitations documented

---

## 🛠️ Technology

Chrome Secure uses a small set of standard Linux tools and Chrome features:

| Technology | Purpose |
|---|---|
| **Bash** | Launcher and authentication logic |
| **Zenity** | Graphical password and profile-selection dialogs |
| **OpenSSL** | Password hashing |
| **Flatpak** | Launching Google Chrome |
| **Google Chrome `--user-data-dir`** | Profile isolation |
| **Linux Desktop Entry** | Integrating the secure launcher with the Chrome application |

---

## 🎯 Project Goal

The goal of Chrome Secure is to provide a simple additional authentication layer for users who maintain multiple Chrome profiles on Linux.

It is useful when:

- Multiple users or identities use separate Chrome profiles
- Different browsing environments need separate access
- A user wants an additional password prompt before Chrome opens
- Chrome profiles should remain isolated during normal use
- Existing Chrome profile data needs to be preserved during migration

---

## 🚀 Basic Workflow

A typical Chrome Secure session looks like this:

```text
┌──────────────────────┐
│ Fedora Desktop       │
│ Already Unlocked     │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Click Chrome Icon    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Master Password      │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Profile Selection    │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Profile Password     │
└──────────┬───────────┘
           │
           ▼
┌──────────────────────┐
│ Isolated Chrome      │
│ Environment          │
└──────────────────────┘
```

---

## 📁 Project Structure

```text
chrome-secure/
│
├── README.md
├── LICENSE
├── SECURITY.md
│
├── config/
│   └── desktop-entry.template
│
├── docs/
│   ├── DETAILED.md
│   └── recovery.md
│
└── scripts/
    ├── chrome-secure.sh
    ├── install.sh
    ├── setup-passwords.sh
    └── uninstall.sh
```

### Important Files

#### `scripts/chrome-secure.sh`

The main launcher responsible for:

- Master password authentication
- Profile selection
- Profile password authentication
- Launching the selected isolated Chrome environment

#### `scripts/install.sh`

Handles installation of the launcher and desktop integration.

#### `scripts/setup-passwords.sh`

Handles creation of the local authentication configuration.

#### `scripts/uninstall.sh`

Provides the uninstall process.

#### `config/desktop-entry.template`

Template for integrating Chrome Secure with the Linux application launcher.

#### `docs/DETAILED.md`

Contains the complete technical documentation.

#### `docs/recovery.md`

Contains recovery and troubleshooting procedures.

---

## 🔄 Existing Chrome Profiles

Chrome Secure can be configured around existing Chrome profile data.

A migration process can create isolated environments while preserving important browser data such as:

- History
- Bookmarks
- Extensions
- Browser settings
- Existing Chrome profile data
- Existing authenticated sessions where supported

Always create and verify a backup before modifying Chrome profile storage.

---

## 💾 Backup Recommendation

Before changing Chrome profile storage or authentication configuration:

1. Close Chrome completely.
2. Create a verified backup.
3. Confirm that the backup is accessible.
4. Perform the configuration change.
5. Test the system.
6. Keep the previous backup until the new configuration is confirmed.

**Never delete the original Chrome data simply because Chrome Secure is working.**

---

## 🔒 Security Model

Chrome Secure should be understood as a **launcher-level access-control mechanism**.

It adds authentication before launching the selected Chrome environment, but it does **not encrypt Chrome profile data**.

The underlying Linux user account remains the primary security boundary.

A person who already has full control of the Linux account may potentially:

- Launch Chrome directly
- Modify the launcher
- Modify configuration files
- Access Chrome profile directories
- Bypass the launcher
- Use administrative/root privileges

For stronger isolation, consider combining Chrome Secure with:

- Separate Linux user accounts
- Proper filesystem permissions
- Full-disk or filesystem encryption
- Strong Linux account authentication

---

## ⚠️ Important Security Notice

Chrome Secure is intended as an **additional protection layer** for Chrome profile access.

It should **not** be considered equivalent to operating-system-level account isolation.

Do not use the project as the only protection for highly sensitive information.

The project is designed primarily to control access through the Chrome launcher and isolate normal Chrome profile usage.

---

## 📚 Documentation

This repository provides documentation at different levels.

### Quick Overview

You're currently reading the project overview.

### Detailed Documentation

📖 **[Read the Detailed Documentation](docs/DETAILED.md)**

The detailed documentation covers:

- Architecture
- Installation
- Configuration
- Password setup
- Profile migration
- Profile isolation
- Testing
- Troubleshooting
- Backup procedures
- Recovery
- Security model
- Limitations
- Uninstallation
- Rollback procedures

### Recovery Guide

🛠️ **[Read the Recovery Guide](docs/recovery.md)**

Contains procedures for common problems such as:

- Forgotten passwords
- Chrome launch failures
- Missing launcher
- Missing profile data
- Desktop-entry problems
- Emergency recovery

### Security Policy

🛡️ **[Read the Security Policy](SECURITY.md)**

---

## 🧪 Project Status

Chrome Secure is a personal/open-source project focused on experimenting with additional authentication and profile isolation for Google Chrome on Linux.

The project is documented with its architecture, setup process, recovery procedures, and security limitations.

Before using it in a sensitive environment, understand the security model and the limitations described above.

---

## 🤝 Contributing

Contributions, suggestions, documentation improvements, and security reviews are welcome.

Before contributing:

1. Read `SECURITY.md`
2. Do not include personal Chrome data
3. Do not include password hashes
4. Do not include credentials or tokens
5. Keep examples generic and reproducible

---

## 📜 License

Chrome Secure is released under the **MIT License**.

See [`LICENSE`](LICENSE) for the complete license text.
