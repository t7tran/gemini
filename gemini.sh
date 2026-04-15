#!/usr/bin/env bash

export NPM_CONFIG_PREFIX=${HOME}/.npm-packages

ensure_extension() {
  local ext=$1 path=$2
  if [ ! -d ~/.gemini/extensions/$ext ]; then gemini extensions install $path --consent --auto-update; fi
}

args=(); for arg in "$@"; do [[ "$arg" != "--no-update" ]] && args+=("$arg"); done

if [[ "$@" != *--no-update* ]]; then
  npm install --loglevel=silent -g @google/gemini-cli@latest
  ensure_extension conductor https://github.com/gemini-cli-extensions/conductor
  ensure_extension Stitch    https://github.com/gemini-cli-extensions/stitch
  gemini extensions update --all
  docker pull ghcr.io/t7tran/nodedev:lts
fi

command=( docker run -it --rm \
                      --user $(id -u):$(id -g) \
                      -e HOME=/home/node \
                      -v "$PWD":/home/node/`basename "$PWD"` \
                      --workdir /home/node/`basename "$PWD"` \
                      -e NPM_CONFIG_PREFIX=/home/node/.npm-packages \
                      -v ${HOME}/.npm-packages:/home/node/.npm-packages \
                      -e GOOGLE_CLOUD_PROJECT \
                      -e TERM=$TERM -e COLORTERM=$COLORTERM \
)

if [[ -f $HOME/.gitconfig ]]; then
	command+=( -v $HOME/.gitconfig:/home/node/.gitconfig:ro )
fi
if [[ -d $HOME/.gemini ]]; then
	command+=( -v $HOME/.gemini:/home/node/.gemini )
fi
if [[ -d $HOME/git ]]; then
	command+=( -v $HOME/git:/home/node/git:ro )
fi

command+=( ghcr.io/t7tran/nodedev:lts gemini )

if [[ -d $HOME/git ]]; then
	command+=( --include-directories /home/node/git )
fi

exec "${command[@]}" "${args[@]}"
