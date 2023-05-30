# Rails Tooling

## devenv setup

1. [Install nix](https://github.com/DeterminateSystems/nix-installer)
2. Set up cachix:

```sh
nix profile install nixpkgs#cachix
cachix use devenv
# Note: it's ok to run the command to make your user a nix admin
```

3. Install devenv:

```sh
nix profile install --accept-flake-config github:cachix/devenv/latest
```

4. Install [OrbStack](https://orbstack.dev/)
5. Install direnv:

```sh
brew install direnv
```

6. Add the following lines to your ~/.zshrc:

```sh
export DIRENV_LOG_FORMAT=
eval "$(direnv hook zsh)"
```

7. Change to your repository
8. `direnv allow`
9. Watch as devenv builds your environment.

## App setup

1. `bundle install`
2. `yarn install`
3. `docker compose up -d` (starts databases in docker containers)
4. `bin/setup`
5. `dev up -df` (starts rails, etc)
6. Open [localhost:3000](http://localhost:3000) in your browser


## dev reference

### Commands

- `dev up -df` starts containers and processes in the background (that's the `-d`) and follows the output (that's the `-f`)
- `dev down` shuts down containers and processes
- `dev logs` Displays process and container logs
- `dev restart` restarts any combination of processes and containers
- `dev ps` displays the status of all containers and processes
