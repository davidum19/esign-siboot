# E-Sign for Open Minis

This directory contains a lightweight launcher for the official AppleJR E-Sign installer.

## Usage

Run from Open Minis:

```sh
sh install.sh
```

The default command is `install`. The launcher also forwards these commands to the official installer:

- `check`
- `pair`
- `developer-mode`
- `sign-out`

For example:

```sh
sh install.sh check
```

## What the launcher does

- Checks that it is running on Linux ARM64.
- Checks for the Open Minis helper commands `minis-bonjour` and `minis-open`, plus `sha256sum`.
- Downloads the official AppleJR E-Sign installer from `applejr.net`.
- Tries the XZ and GZIP variants before falling back to the raw binary.
- Verifies the published SHA-256 digest of the downloaded archive and the extracted executable.
- Stores the verified executable at `~/.e-sign/bin/e-sign-installer` and forwards the requested command.

The executable itself is proprietary and is **not included in this repository**. It is downloaded directly from AppleJR when the launcher runs.

## Version information

- E-Sign installer: 0.2.2
- Build: 24
- Target architecture: aarch64
