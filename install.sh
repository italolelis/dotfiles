#!/bin/sh

cd "$(dirname "${BASH_SOURCE}")";

git pull origin main;

function doIt() {
	echo "🚀 Installing dotfiles..."

	# Create necessary directories (platform-agnostic)
	mkdir -p ~/.zsh/cache
	mkdir -p ~/.npm-global
	mkdir -p ~/.ssh

	# Sync dotfiles
	rsync --exclude ".git/" \
		--exclude ".DS_Store" \
		--exclude ".osx" \
		--exclude "install.sh" \
		--exclude "README.md" \
		-avh --no-perms . ~;

	echo "✅ Dotfiles synced successfully!"

	# Install Oh My Zsh if not already installed
	if [ ! -d "$HOME/.oh-my-zsh" ]; then
		echo "📦 Installing Oh My Zsh..."
		sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
	else
		echo "✅ Oh My Zsh already installed"
	fi

	# Install required Oh My Zsh plugins
	echo "🔌 Installing Oh My Zsh plugins..."

	# zsh-autosuggestions
	if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
		echo "📦 Installing zsh-autosuggestions..."
		git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
	else
		echo "✅ zsh-autosuggestions already installed"
	fi

	# zsh-syntax-highlighting
	if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
		echo "📦 Installing zsh-syntax-highlighting..."
		git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
	else
		echo "✅ zsh-syntax-highlighting already installed"
	fi

	# Set up global gitignore (platform-agnostic)
	if command -v git &> /dev/null; then
		echo "🔧 Setting up global gitignore..."
		git config --global core.excludesfile ~/.gitignore_global
	else
		echo "⚠️  Git not found, skipping gitignore setup"
	fi

	echo "🎉 Installation complete! Please restart your terminal or run 'source ~/.zshrc'"
}

if [ "$1" == "--force" -o "$1" == "-f" ]; then
	doIt;
else
	read -p "This may overwrite existing files in your home directory. Are you sure? (y/n) " -n 1;
	echo "";
	if [[ $REPLY =~ ^[Yy]$ ]]; then
		doIt;
	fi;
fi;
unset doIt;
