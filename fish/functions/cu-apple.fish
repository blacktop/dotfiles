function cu-apple --description 'Use Apple container as the backend for Container Use (start/stop/status)'
    set -l cmd (count $argv) > /dev/null; and set -l sub $argv[1]; or set -l sub status

    switch $sub
    case on
        if not type -q container
            echo "cu-apple: missing 'container' CLI (macOS 26+, Apple silicon)"; return 127
        end
        # Start Apple container system service
        container system start

        # Provide a docker-compatible shim so Dagger/Container Use can talk to Apple 'container'
        if not test -e /usr/local/bin/docker
            set -l cbin (command -s container)
            test -n "$cbin"; or begin; echo "cu-apple: cannot locate 'container' binary"; return 127; end
            sudo ln -s $cbin /usr/local/bin/docker
        end

        # Start (or reuse) a Dagger engine container under Apple 'container'
        set -l engine (set -q DAGGER_ENGINE_IMAGE; and echo $DAGGER_ENGINE_IMAGE; or echo registry.dagger.io/engine:v0.18.14)
        set -l running (container ls | string match -r '^\s*dagger-engine-custom\b')
        if test -z "$running"
            container run --rm -d --name dagger-engine-custom $engine
        end

        # Point Container Use/Dagger at that engine
        set -Ux _EXPERIMENTAL_DAGGER_RUNNER_HOST docker-container://dagger-engine-custom
        echo "cu-apple: runner -> $_EXPERIMENTAL_DAGGER_RUNNER_HOST"
    case off
        if type -q container
            container kill dagger-engine-custom 2>/dev/null
        end
    case status '*'
        if type -q container
            echo "container version:"; container version 2>/dev/null
            echo
            echo "active containers:"; container ls 2>/dev/null
        else
            echo "container CLI not found"
        end
        if set -q _EXPERIMENTAL_DAGGER_RUNNER_HOST
            echo; echo "_EXPERIMENTAL_DAGGER_RUNNER_HOST=$_EXPERIMENTAL_DAGGER_RUNNER_HOST"
        else
            echo; echo "_EXPERIMENTAL_DAGGER_RUNNER_HOST is not set"
        end
    end
end
