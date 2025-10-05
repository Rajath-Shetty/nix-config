# Templates for NixOS Configuration

This directory contains templates for quickly setting up new projects and configurations.

## .envrc Templates

Copy these to your project directory and rename to `.envrc`:

### Basic Usage

```bash
# Copy template to your project
cp ~/nixos-config/templates/.envrc ~/myproject/.envrc

# Allow direnv to use it
cd ~/myproject
direnv allow
```

### Available Templates

- **`.envrc`** - Basic flake-based setup
- **`.envrc.python`** - Python development with Poetry
- **`.envrc.rust`** - Rust development with Cargo
- **`.envrc.node`** - Node.js development with npm/pnpm
- **`.envrc.custom`** - Advanced custom configuration

### How It Works

When you `cd` into a directory with `.envrc`:
1. direnv automatically loads the environment
2. Nix packages become available
3. Environment variables are set
4. PATH is updated

When you `cd` out:
- Everything is unloaded automatically
- No system pollution

## Quick Start Examples

### Python Project

```bash
mkdir ~/my-python-app && cd ~/my-python-app
cp ~/nixos-config/templates/.envrc.python .envrc
direnv allow

# Python dev environment is now active!
python --version
poetry --version
```

### Rust Project

```bash
cargo new my-rust-app && cd my-rust-app
cp ~/nixos-config/templates/.envrc.rust .envrc
direnv allow

# Rust dev environment is now active!
rustc --version
cargo --version
```

### Node.js Project

```bash
mkdir ~/my-node-app && cd ~/my-node-app
npm init -y
cp ~/nixos-config/templates/.envrc.node .envrc
direnv allow

# Node dev environment is now active!
node --version
npm --version
```

## Advanced Usage

### Multiple Environments in One Project

```bash
# .envrc
if [ -f ".env.local" ]; then
  dotenv .env.local
fi

use flake .#python
use flake .#node  # Load both!

# Custom settings
export API_KEY="secret"
```

### Per-Directory Settings

```
myproject/
├── .envrc              # Root: use flake .#web
├── backend/
│   └── .envrc          # Python: use flake .#python
└── frontend/
    └── .envrc          # Node: use flake .#node
```

Each directory gets its own environment!

### CI/CD Integration

In GitHub Actions:
```yaml
- name: Setup Nix
  uses: cachix/install-nix-action@v22

- name: Load devShell
  run: nix develop .#python -c pytest
```

## Tips

1. **Always run `direnv allow`** after creating/editing `.envrc`
2. **Check status**: `direnv status`
3. **Reload manually**: `direnv reload`
4. **Debug issues**: `direnv allow` shows errors
5. **Block directory**: `direnv deny`

## Common Patterns

### Database in Dev Environment

```bash
# .envrc
use flake .#python

# Start PostgreSQL locally
export PGDATA="$PWD/.postgres"
export PGHOST="$PGDATA"

if [ ! -d "$PGDATA" ]; then
  initdb
  echo "unix_socket_directories = '$PGDATA'" >> $PGDATA/postgresql.conf
  pg_ctl start -l $PGDATA/postgres.log
fi
```

### Docker Compose Integration

```bash
# .envrc
use flake .#node

# Auto-start services
if ! docker-compose ps | grep -q "Up"; then
  docker-compose up -d
fi
```

### Secrets Management

```bash
# .envrc
use flake

# Load secrets from 1Password, pass, etc.
export API_KEY=$(op read "op://dev/api-key/credential")
export DB_PASSWORD=$(pass show db/password)
```

## Troubleshooting

### direnv not activating?
```bash
# Check if direnv is installed
which direnv

# Check shell integration
echo $SHELL
# Make sure you added hook to your shell config
```

### Slow loading?
```bash
# nix-direnv caches the environment
# First load is slow, subsequent loads are instant

# Clear cache if needed
rm -rf .direnv/
```

### Environment not updating?
```bash
# Force reload
direnv reload

# Or update the flake
nix flake update
direnv reload
```
