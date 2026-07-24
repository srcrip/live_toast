# Run tests
test:
    cd demo && mix test

# Run tests in interactive loop (re-runs on file changes)
test_interactive:
    cd demo && fswatch ../lib lib test | mix test --listen-on-stdin

# Run the demo app and docs server concurrently
dev:
    #!/usr/bin/env bash
    trap 'kill 0' EXIT
    (cd demo && mix phx.server) &
    mix docs.run &
    echo "Running demo site on localhost:4004. Opening browser..."
    open http://localhost:4004
    echo "Running docs site on localhost:8000. Opening browser..."
    open http://localhost:8000
    wait

# Verify the main branch is ready to publish to Hex without publishing it
release-preflight:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Checking out the main branch..."
    git checkout main
    echo "==> Fast-forwarding main from origin..."
    git pull --ff-only origin main
    echo "==> Fetching Elixir dependencies..."
    mix deps.get
    echo "==> Installing locked JavaScript dependencies..."
    (cd assets && bun install --frozen-lockfile)
    echo "==> Rebuilding published LiveToast JavaScript artifacts..."
    mix assets.build
    echo "==> Reviewing generated JavaScript artifact changes..."
    git diff -- priv/static
    echo "==> Type-checking and testing JavaScript..."
    (cd assets && bun run typecheck && bun test)
    echo "==> Compiling Elixir without warnings..."
    mix compile --warnings-as-errors
    echo "==> Checking Elixir formatting..."
    mix format --check-formatted
    echo "==> Testing the demo application..."
    (cd demo && mix deps.get && mix test)
    echo "==> Dry-running the Hex publish..."
    mix hex.publish --dry-run
    echo "==> Building and unpacking the Hex archive for inspection..."
    mix hex.build --unpack
