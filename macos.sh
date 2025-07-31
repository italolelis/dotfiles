#!/bin/sh

# Path to your dotfiles.
export DOTFILES=$HOME/.dotfiles

echo "🚀 Setting up your Mac..."

# Check for Homebrew and install if we don't have it
if test ! $(which brew); then
  echo "🍺 Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add Homebrew to PATH for Apple Silicon Macs
  if [[ $(uname -m) == 'arm64' ]]; then
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
    eval "$(/opt/homebrew/bin/brew shellenv)"
  else
    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> $HOME/.zprofile
    eval "$(/usr/local/bin/brew shellenv)"
  fi
else
  echo "✅ Homebrew already installed"
fi

# Make sure we're using the latest Homebrew.
echo "📦 Updating Homebrew..."
brew update

# Upgrade any already-installed formulae.
echo "⬆️  Upgrading packages..."
brew upgrade

# Install all our dependencies with bundle (See Brewfile)
echo "📦 Installing packages from Brewfile..."
brew tap homebrew/bundle
brew bundle --file $DOTFILES/install/Brewfile

# Create necessary directories
echo "📁 Creating necessary directories..."
mkdir -p ~/.zsh/cache
mkdir -p ~/.npm-global
mkdir -p ~/.config/git

# Set up global gitignore
if command -v git &> /dev/null; then
  echo "🔧 Setting up global gitignore..."
  git config --global core.excludesfile ~/.gitignore_global
else
  echo "⚠️  Git not found, skipping gitignore setup"
fi

# Symlink the Mackup config file to the home directory (if it exists)
if [ -f "$DOTFILES/.mackup.cfg" ]; then
  echo "🔗 Setting up Mackup..."
  ln -sf $DOTFILES/.mackup.cfg $HOME/.mackup.cfg
fi

# Set macOS preferences - we will run this last because this will reload the shell
echo "⚙️  Applying macOS preferences..."
source $DOTFILES/.macos

# Run the main installation script
echo "🔧 Running main installation..."
$DOTFILES/install.sh

# Remove outdated versions from the cellar
echo "🧹 Cleaning up Homebrew..."
brew cleanup

echo "🎉 Mac setup complete! Please restart your computer to apply all changes."
