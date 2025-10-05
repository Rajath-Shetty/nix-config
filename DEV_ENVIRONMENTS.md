# Development Environments Guide

This configuration includes powerful per-project development environments using Nix flakes and direnv.

## Quick Start

### 1. Enable the Development Role

Make sure your host has the `development` role:

```nix
# parts/hosts.nix
my-laptop = self.lib.mkSystem {
  hostname = "my-laptop";
  roles = [ "development" ];  # This enables direnv!
};
```

Rebuild:
```bash
sudo nixos-rebuild switch --flake .#my-laptop
```

### 2. Create a Project

```bash
mkdir ~/my-python-project && cd ~/my-python-project
```

### 3. Add .envrc

```bash
echo "use flake ~/nixos-config#python" > .envrc
direnv allow
```

**That's it!** Python and all dev tools are now available in this directory only.

## Available Development Shells

| Shell | Command | Includes |
|-------|---------|----------|
| **Python** | `nix develop .#python` | Python 3.11, pip, poetry, pytest, black, ipython |
| **Rust** | `nix develop .#rust` | rustc, cargo, rustfmt, clippy, rust-analyzer |
| **Node.js** | `nix develop .#node` | Node 20, npm, pnpm, yarn, TypeScript, TSServer |
| **Go** | `nix develop .#go` | Go, gopls, gotools |
| **C/C++** | `nix develop .#cpp` | GCC, Clang, CMake, GDB, Valgrind |
| **Web** | `nix develop .#web` | Node + Python + Flask + Django |
| **Default** | `nix develop` | Nix tools, git (for managing configs) |

## Using direnv (Recommended)

### What is direnv?

- Automatically loads dev environment when you `cd` into a directory
- Unloads when you leave
- Works with any shell (bash, zsh, fish)
- Cached by nix-direnv (instant activation)

### Setup

Already enabled if you have the `development` role! Just use it:

```bash
# Python project
cd ~/my-python-app
echo "use flake ~/nixos-config#python" > .envrc
direnv allow

# Rust project
cd ~/my-rust-app
echo "use flake ~/nixos-config#rust" > .envrc
direnv allow
```

### Templates

Copy templates from [templates/](templates/):

```bash
# Python
cp ~/nixos-config/templates/.envrc.python ~/my-project/.envrc

# Rust
cp ~/nixos-config/templates/.envrc.rust ~/my-project/.envrc

# Node
cp ~/nixos-config/templates/.envrc.node ~/my-project/.envrc

# Custom
cp ~/nixos-config/templates/.envrc.custom ~/my-project/.envrc
```

Then: `direnv allow`

## Manual Usage (Without direnv)

### Enter a shell manually:

```bash
cd ~/my-project
nix develop ~/nixos-config#python

# Now in Python dev environment
python --version
poetry --version
```

### Run single command:

```bash
nix develop ~/nixos-config#python -c "python script.py"
nix develop ~/nixos-config#rust -c "cargo build"
```

## Examples

### Python Web App

```bash
mkdir ~/my-flask-app && cd ~/my-flask-app

# Setup direnv
cat > .envrc << 'EOF'
use flake ~/nixos-config#python
export FLASK_APP=app.py
export FLASK_ENV=development
EOF

direnv allow

# Now use Python tools
poetry init
poetry add flask
python -m flask run
```

### Rust CLI Tool

```bash
cargo new my-tool && cd my-tool

# Setup direnv
echo "use flake ~/nixos-config#rust" > .envrc
direnv allow

# Tools are ready
cargo build
cargo test
cargo clippy
```

### Full-Stack Project

```
my-fullstack-app/
├── .envrc                    # use flake ~/nixos-config#web
├── backend/
│   ├── .envrc               # use flake ~/nixos-config#python
│   └── app.py
└── frontend/
    ├── .envrc               # use flake ~/nixos-config#node
    └── package.json
```

Each directory gets its own isolated environment!

## Creating Custom Dev Shells

### In Your Project Flake

Create `flake.nix` in your project:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { nixpkgs, ... }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in {
      devShells.x86_64-linux.default = pkgs.mkShell {
        packages = with pkgs; [
          python311
          postgresql
          redis
          # Project-specific packages
        ];

        shellHook = ''
          echo "Welcome to MyApp dev environment"
          export DATABASE_URL="postgresql://localhost/myapp"
        '';
      };
    };
}
```

Then:
```bash
echo "use flake" > .envrc
direnv allow
```

### Extending Existing Shells

```nix
# flake.nix in your project
{
  inputs = {
    nixos-config.url = "path:/home/user/nixos-config";
  };

  outputs = { self, nixos-config, ... }: {
    devShells.x86_64-linux.default = nixos-config.devShells.x86_64-linux.python.overrideAttrs (old: {
      buildInputs = old.buildInputs ++ [ pkgs.mongodb ];
    });
  };
}
```

## Advanced Patterns

### Multi-Language Monorepo

```bash
# Root .envrc
use flake ~/nixos-config#web

# services/api/.envrc
use flake ~/nixos-config#python

# services/worker/.envrc
use flake ~/nixos-config#rust

# frontend/.envrc
use flake ~/nixos-config#node
```

### Database in Dev Environment

```bash
# .envrc
use flake ~/nixos-config#python

export PGDATA="$PWD/.postgres"
if [ ! -d "$PGDATA" ]; then
  initdb
  pg_ctl start -l $PGDATA/postgres.log
fi
```

### Docker + Dev Shell

```bash
# .envrc
use flake ~/nixos-config#node

# Auto-start Docker services
docker-compose up -d

# Set connection strings
export DATABASE_URL="postgresql://localhost:5432/app"
export REDIS_URL="redis://localhost:6379"
```

### Secret Management

```bash
# .envrc
use flake ~/nixos-config#python

# Load from password manager
export API_KEY=$(pass show api/key)
export AWS_PROFILE=dev

# Or use .env file (gitignored)
dotenv .env.local
```

## CI/CD Integration

### GitHub Actions

```yaml
name: Test
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: cachix/install-nix-action@v22
      - name: Test
        run: nix develop ~/nixos-config#python -c pytest
```

### GitLab CI

```yaml
test:
  image: nixos/nix
  script:
    - nix develop ~/nixos-config#rust -c cargo test
```

## Troubleshooting

### direnv not working?

```bash
# Check if installed
which direnv

# Check hook is loaded
echo $DIRENV_DIR  # Should output something when in a direnv directory

# Reload your shell config
source ~/.bashrc  # or ~/.zshrc
```

### Slow first load?

First load downloads packages. Subsequent loads are instant thanks to nix-direnv cache:

```bash
# First time (slow)
cd my-project  # Downloads Python, builds environment...

# After that (instant)
cd my-project  # ✨ Already cached!
```

### Environment not updating?

```bash
# Reload direnv
direnv reload

# Or update the flake
cd ~/nixos-config
nix flake update
direnv reload
```

### Can't find packages?

Make sure you're using the right shell:

```bash
# Wrong
echo "use flake" > .envrc  # Uses project's flake (doesn't exist)

# Right
echo "use flake ~/nixos-config#python" > .envrc  # Uses system config
```

## Tips & Best Practices

1. **One .envrc per project** - Each project gets isolated environment
2. **Commit .envrc** - Team members get same environment
3. **Don't commit .direnv/** - Add to .gitignore (this is cache)
4. **Use templates** - Start from [templates/](templates/)
5. **Layer environments** - Combine multiple shells if needed
6. **Cache is king** - nix-direnv makes it instant after first load

## Comparison with Other Tools

| Feature | Nix + direnv | venv/virtualenv | Docker | asdf/mise |
|---------|-------------|-----------------|---------|-----------|
| Isolated | ✅ | ✅ | ✅ | ❌ |
| Reproducible | ✅ | ⚠️ | ✅ | ❌ |
| Fast | ✅ | ✅ | ❌ | ✅ |
| System packages | ✅ | ❌ | ✅ | ⚠️ |
| Auto-activation | ✅ | ❌ | ❌ | ✅ |
| Cross-platform | ⚠️ | ✅ | ✅ | ✅ |

## Learning More

- Nix Dev Shells: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-develop
- direnv: https://direnv.net/
- nix-direnv: https://github.com/nix-community/nix-direnv
- Template examples: [templates/README.md](templates/README.md)

Happy coding! 🚀
