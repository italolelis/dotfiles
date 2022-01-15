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

user_rc_file="$HOME/.zshrc"
powerlevel10k_dir="${ZSH}/custom/themes/powerlevel10k"
if [ ! -d "$powerlevel10k_dir" ]; then
	git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${powerlevel10k_dir}
	sed -i 's/ZSH_THEME=.*/ZSH_THEME="powerlevel10k/powerlevel10k"/g' ${user_rc_file}
fi
