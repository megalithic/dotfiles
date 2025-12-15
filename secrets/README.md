# Agenix Secrets Management

This directory contains encrypted secrets managed by [agenix](https://github.com/ryantm/agenix).

## Overview

Agenix uses your SSH keys (stored in 1Password) to encrypt/decrypt secrets. Secrets are:
- Encrypted with your SSH public key
- Stored safely in git as `.age` files
- Decrypted automatically during system activation to `~/.config/agenix/`
- Never stored in plaintext in the repository

## Prerequisites

1. **SSH key available via 1Password SSH agent**
   - Your SSH key is already configured in `~/.ssh/config`
   - Verify: `ssh-add -L` should show your key

2. **Agenix CLI installed**
   - Automatically available after `darwin-rebuild switch`
   - Or install manually: `nix profile install github:ryantm/agenix`

## Quick Start

### 1. Create a New Secret

```bash
cd ~/.dotfiles-nix/secrets

# Create/edit a secret (opens in $EDITOR)
agenix -e env-vars.age

# Add your environment variables in export format:
export PUSHOVER_USER_TOKEN="your-user-token"
export PUSHOVER_APP_TOKEN="your-app-token"
export GITHUB_TOKEN="ghp_xxx"
# ... etc
```

### 2. Rebuild to Decrypt Secrets

```bash
# From dotfiles-nix directory
just mac  # or: darwin-rebuild switch --flake .
```

### 3. Verify Secrets Are Loaded

```bash
# Secrets are decrypted to ~/.config/agenix/
ls -la ~/.config/agenix/

# Check environment variables (start new shell first)
echo $PUSHOVER_USER_TOKEN
```

## Available Secrets

Defined in `secrets.nix`:

- **env-vars.age** - Shell environment variables (auto-loaded in zsh/fish)
- **api-keys.age** - API keys and tokens
- **github-token.age** - GitHub personal access token

## Common Operations

### Edit an Existing Secret

```bash
agenix -e env-vars.age
```

### Add a New Secret

1. Edit `secrets.nix` and add the new secret definition:
   ```nix
   "my-new-secret.age".publicKeys = allKeys;
   ```

2. Edit `home/agenix.nix` and add to `age.secrets`:
   ```nix
   my-new-secret = {
     file = ../../secrets/my-new-secret.age;
   };
   ```

3. Create the encrypted secret:
   ```bash
   agenix -e my-new-secret.age
   ```

4. Rebuild:
   ```bash
   just mac
   ```

### Add Another SSH Key

1. Get the public key:
   ```bash
   ssh-add -L  # or: cat ~/.ssh/id_ed25519.pub
   ```

2. Edit `secrets.nix` and add it to `allKeys`

3. Rekey all secrets:
   ```bash
   agenix -r
   ```

### Migrate from 1Password

Instead of fetching tokens from 1Password every time (like scripts using `op read`), store them in agenix:

1. Get the value from 1Password:
   ```bash
   op read "op://Shared/bjdr5wcxdv6eeq3yylc25vvofy/PUSHOVER_USER_TOKEN"
   ```

2. Add to `env-vars.age`:
   ```bash
   agenix -e env-vars.age
   # Add: export PUSHOVER_USER_TOKEN="the-value-from-1password"
   ```

3. Update scripts to use environment variable instead of `op read`

## Environment Variable Format

The `env-vars.age` file should contain standard shell export statements:

```bash
# Good - shell export format
export API_KEY="value"
export TOKEN="another-value"

# Also works - posix compatible
API_KEY="value"
TOKEN="another-value"
export API_KEY TOKEN
```

Both formats work with `source` command used in shell configs.

## Security Notes

- ✅ `.age` files are safe to commit - they're encrypted
- ⚠️ Never commit decrypted secrets (`.gitignore` prevents this)
- ⚠️ Secrets are decrypted to `~/.config/agenix/` on your machine
- ✅ Only machines with the private SSH key can decrypt
- ✅ 1Password manages your SSH private key securely

## Troubleshooting

### "Error: No such file or directory" when editing

Make sure you're in the secrets directory or use the full path:
```bash
cd ~/.dotfiles-nix/secrets
agenix -e env-vars.age
```

### "Could not find SSH keys"

Verify your SSH key is accessible:
```bash
ssh-add -L  # Should show your ed25519 key from 1Password
```

### Secrets not loading in shell

1. Rebuild to decrypt: `just mac`
2. Start a new shell session
3. Check secret exists: `cat ~/.config/agenix/env-vars`
4. Check shell config sources it (already configured in agenix.nix)

### Permission denied on secret files

The agenix module handles permissions. Decrypted secrets in `~/.config/agenix/` should be:
- Owned by your user
- Mode 0400 (read-only by owner)

## References

- [Agenix GitHub](https://github.com/ryantm/agenix)
- [Using Agenix with Home Manager](https://www.mitchellhanberg.com/using-agenix-with-home-manager/)
- [Agenix NixOS Wiki](https://nixos.wiki/wiki/Agenix)
