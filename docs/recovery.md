# Recovery Guide

This document describes common recovery procedures for Chrome Secure.

---

## 1. Forgot the Master Password

The master password cannot be recovered from its password hash.

If the original password is unavailable, create a new password hash.

Do not delete Chrome profile data unless a verified backup exists.

---

## 2. Forgot a Profile Password

Profile passwords are represented by password hashes.

The original password cannot be recovered from the hash.

Create a new authorized password hash when appropriate.

---

## 3. Chrome Will Not Launch

Check whether Chrome is already running:

```bash
pgrep -a chrome
