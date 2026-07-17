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
