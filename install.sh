#!/usr/bin/env bash

# Path to your dotfiles.
export DOTFILES=$HOME/dotfiles

cd "$(dirname "${BASH_SOURCE}")";

git pull origin main;

function doIt() {
	rsync --exclude ".git/" \
		--exclude ".DS_Store" \
		--exclude ".osx" \
		--exclude "install.sh" \
		--exclude "README.md" \
		-avh --no-perms . ~;
	source ~/.zshrc;
}

function ohMyZsh() {
	oh_my_install_dir="$HOME/.oh-my-zsh"
	user_rc_file="$HOME/.zshrc"

	sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

	powerlevel10k_dir="${oh_my_install_dir}/.oh-my-zsh/custom/themes/powerlevel10k"
	if [ ! -d "$oh_my_install_dir" ]; then
		git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${powerlevel10k_dir}
		sed -i -e 's/ZSH_THEME=.*/ZSH_THEME="powerlevel10k/powerlevel10k"/g' ${user_rc_file}
	fi
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	ohMyZsh;
	doIt;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		ohMyZsh;
		doIt;
	fi;
fi;
unset ohMyZsh;
unset doIt;
