# GitHub Actions Runner with Docker Compose

Spin up a repository‑scoped, ephemeral self‑hosted GitHub Actions runner using Docker Compose. This repo wraps the excellent `myoung34/github-runner` image with a tiny `docker-compose.yml` and a convenience `Makefile` for one‑liner setup.

- Ephemeral by default: one job per container start, then the container exits and is restarted automatically.
- Safe defaults: auto‑update disabled, runner name prefix, useful labels.
- Docker‑in‑Docker (DinD) compatible: the runner can build/run containers via the host Docker socket.

See `docker-compose.yml` and `Makefile` for the exact configuration.

## Requirements

- Docker with Compose v2 (`docker compose ...`).
- Optional but recommended: GitHub CLI `gh` to auto‑supply a token.
- A GitHub token that can register a repository runner:
  - Using the Makefile: run `gh auth login` first; we read `gh auth token` at runtime.
  - Manual compose: provide `GH_PAT` with at least the `repo` scope (fine‑grained token: Repository permissions → Administration: Read/Write).

## Quick Start (Makefile)

The Makefile resolves your target repo from several formats and injects a token from the GitHub CLI.

1) Authenticate `gh` once if you haven’t yet:

```bash
gh auth login
```

2) Start a runner for a repository (background):

```bash
make run TARGET=owner/repo
# or: make run TARGET=https://github.com/owner/repo
# or: make run REPO=owner/repo
```

- Foreground logs (Ctrl+C to stop):

```bash
make run-fg TARGET=owner/repo
```

3) Verify in GitHub → your repo → Settings → Actions → Runners. You should see a runner named like `ghr-<repo>-<…>` with labels `self-hosted,linux,x64,<owner>-<repo>`.

## Quick Start (Manual Compose)

If you prefer not to use `gh`, export the required env vars and bring the stack up directly:

```bash
export REPO_URL="https://github.com/owner/repo"
export GH_PAT="<your PAT with repo scope>"
# Optional overrides
export CONTAINER_NAME="github-runner"
export EPHEMERAL=1
export DISABLE_AUTO_UPDATE=1
export RUNNER_LABELS="self-hosted,linux,x64"
export RUNNER_NAME_PREFIX="ghr-"

docker compose -f docker-compose.yml up -d
```

## Managing The Runner

- Status: `make status`
- Follow logs: `make logs`
- Stop and remove container: `make down` (alias `make stop`)
- Restart with the same target: `make restart TARGET=owner/repo`

Notes:
- The container name defaults to `github-runner`. Override with `CONTAINER_NAME=...` for commands that inspect logs/status.
- In ephemeral mode (`EPHEMERAL=1`) each job terminates the container; Compose restarts it automatically due to `restart: always`.

## Configuration

All knobs live in `docker-compose.yml` and can be overridden via environment variables when you run Compose or `make`:

- `RUNNER_SCOPE` = `repo` (fixed by this stack; organization scope is not wired here)
- `REPO_URL` = `https://github.com/<owner>/<repo>` (required)
- `GH_PAT` = GitHub token (required unless using the Makefile with `gh`)
- `EPHEMERAL` = `1` (default; set `0` to keep the runner alive for multiple jobs)
- `DISABLE_AUTO_UPDATE` = `1` (default; set `0` to allow runner self‑updates)
- `RUNNER_NAME_PREFIX` = `ghr-` (overridden by the Makefile to include the repo name)
- `RUNNER_LABELS` = `self-hosted,linux,x64` (the Makefile also adds `<owner>-<repo>`)
- `CONTAINER_NAME` = container name used for logs/status (default `github-runner`)

Tip: You may place these in a local shell profile before running, or export them inline for a single invocation.

## Multiple Runners

You can run more than one runner on the same host. Give each instance a unique container and name prefix:

```bash
CONTAINER_NAME=github-runner-1 make run TARGET=owner/repo
CONTAINER_NAME=github-runner-2 RUNNER_NAME_PREFIX=ghr-repo2- make run TARGET=owner/another-repo
```

Because this compose file pins `RUNNER_SCOPE=repo`, each container registers to the specific repository you pass.

## Security Notes

- The runner mounts the host Docker socket (`/var/run/docker.sock`). Any workflow with Docker access can build/run containers with host privileges. Treat the host as fully trusted by the repository you attach to.
- Limit who can push workflows to that repository, or dedicate an isolated host/VM for the runner.
- Prefer ephemeral mode (`EPHEMERAL=1`) to reduce state between jobs.

## Troubleshooting

- “gh CLI not found” when running `make`: install GitHub CLI or use the Manual Compose path.
- “Please export REPO_URL …” or “Please export GH_PAT …”: ensure those env vars are set (Manual Compose) or use `make run TARGET=...` after `gh auth login`.
- No runner appears in Settings → Actions → Runners: check `make logs`, confirm the token has the required scope, and that `REPO_URL` is correct.

## How It Works

- `docker-compose.yml` runs `myoung34/github-runner:latest` with sensible defaults and `restart: always`.
- `Makefile` resolves the repository from `TARGET`/`REPO`, injects `GH_PAT` via `gh auth token`, and sets labels and name prefix so runners are easy to identify.

## License

See `LICENSE` for details.

