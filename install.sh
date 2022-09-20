#!/bin/sh

# Path to your dotfiles.
export DOTFILES=$HOME/dotfiles

cd "$(dirname "${BASH_SOURCE}")";

git pull origin main;

rsync --exclude ".git/" \
	--exclude ".DS_Store" \
	--exclude ".osx" \
	--exclude "install.sh" \
	--exclude "README.md" \
	-avh --no-perms . ~;

sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
