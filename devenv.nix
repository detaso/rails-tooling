{ pkgs, ... }:

{
  # https://devenv.sh/packages/
  packages = with pkgs; [
    git
    nodejs-18_x
    yarn
    postgresql_14
    zlib
    zstd
    libiconv
    tmux
    tmuxPlugins.sensible
    tmuxPlugins.yank
    reattach-to-user-namespace
    getoptions
  ];

  # https://devenv.sh/scripts/
  scripts.dev.exec = ''
    set -euo pipefail

    parser_definition () {
      setup REST help:usage mode:@ -- \
        "Usage: dev [global options...] [command] [options...] [arguments...]"

      msg -- ''' 'dev is a basic wrapper around docker compose and devenv'
      msg -- 'In addition to the commands listed, you may call any docker compose command.' '''

      msg -- 'Options:'
      disp :usage -h --help

      msg -- ''' 'Commands:'
      msg label:up -- "Start containers and processes"
      msg label:down -- "Stop containers and processes"
      msg label:logs -- "Container and process logs"
      msg label:restart -- "Restart containers and processes"
      msg label:ps -- "List containers and processes"
    }

    parser_definition_up () {
      setup REST help:usage -- \
        "Usage: up [options...] [service...]"

      msg -- 'Options:'
      flag FLAG_D -d --detach -- "Detached mode: Run in background"
      flag FLAG_F -f --follow -- "Follow output when detached"
      disp :usage -h --help
    }

    cmd_logs () {
      overmind echo
    }

    cmd_overmind_quit () {
      if [ -S "$DEVENV_ROOT/.overmind.sock" ]; then
        echo "Stopping processes via overmind"
        overmind quit || true
      fi
    }

    eval "$(getoptions parser_definition) exit 1"

    if [ $# -eq 0 ]; then
      usage
      exit 0
    fi

    container_list=(postgres redis)

    case "''${1:-}" in
      restart)
        shift

        containers=()
        processes=()
        for i in "''${@}"; do
          if [[ "''${container_list[*]}" =~ "''${i}" ]]; then
            containers+=("$i")
          else
            processes+=("$i")
          fi
        done

        docker compose rm -sf "''${containers[@]}"
        docker compose up -d "''${containers[@]}"

        overmind restart "''${processes[@]}" "''${containers[@]}"
        ;;
      up)
        shift

        eval "$(getoptions parser_definition_up) exit 1"

        docker compose up -d
        if [ -n "''${FLAG_D:-}" ]; then
          echo "Starting processes via overmind"
          OVERMIND_DAEMONIZE=1 devenv up

          if [ -n "''${FLAG_F:-}" ]; then
            cmd_logs
          fi
        else
          OVERMIND_DAEMONIZE=0 devenv up
        fi
        ;;
      logs)
        cmd_logs
        ;;
      down)
        cmd_overmind_quit
        docker compose down --remove-orphans
        ;;
      ps)
        echo "Containers:"
        docker compose ps
        echo
        echo "Processes:"
        overmind ps
        ;;
      help)
        usage
        ;;
      *)
        docker compose "$@"
        ;;
    esac
  '';

  # https://devenv.sh/languages/
  languages.ruby.enable = true;
  # Uses bobvanderlinden/nixpkgs-ruby to supply any version of ruby
  languages.ruby.versionFile = ./.ruby-version;

  enterShell = ''
    export BUNDLE_BIN="$DEVENV_ROOT/.devenv/bin"
    export PATH="$DEVENV_PROFILE/bin:$DEVENV_ROOT/bin:$BUNDLE_BIN:$PATH"
    export BOOTSNAP_CACHE_DIR="$DEVENV_ROOT/.devenv/state"

    if [ ! -f ~/.tmux.conf ] && [ ! -f ~/.config/tmux/tmux.conf ]; then
      export OVERMIND_TMUX_CONFIG="$DEVENV_ROOT/.overmind.tmux.conf"
    fi
  '';

  # https://devenv.sh/pre-commit-hooks/
  # pre-commit.hooks.shellcheck.enable = true;

  # https://devenv.sh/processes/
  env.OVERMIND_NO_PORT=1;
  env.OVERMIND_ANY_CAN_DIE=1;
  process.implementation = "overmind";

  # The unix socket path can't be "too long".
  # Make sure it's short for when we need it.
  env.RUBY_DEBUG_SOCK_DIR = "/tmp/";

  processes.web.exec = "rdbg -n -O --port 30000 -c -- rails server";

  env.OVERMIND_AUTO_RESTART="postgres";
  processes.postgres.exec = "docker compose logs -f --no-log-prefix postgres";

  env.DATABASE_USERNAME = "postgres";
  env.DATABASE_PASSWORD = "123qweasd";
  env.DATABASE_PORT = "30010";

  # See full reference at https://devenv.sh/reference/options/
}
