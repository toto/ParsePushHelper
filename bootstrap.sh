#!/bin/sh


INTERACTIVE=true

for arg in "$@"; do
  shift
  case "$arg" in
    '--non-interactive')   INTERACTIVE=true   ;;
  esac
done

echo "Updating brew..."
brew update

function install_current {
  echo "Trying to update $1"
  brew upgrade $1 || brew install $1 || true
  brew link $1
}

if [ -e "Mintfile" ]; then
  install_current mint
  mint bootstrap
fi


if [ -e ".ruby-version" ]; then
	echo  "Setting up ruby";
	
	install_current rbenv
	install_current ruby-build
	
	# install ruby version from .ruby-version, skipping if already installed (-s)
	# we need to unset these vars because otherwise rbenv will break
	echo "Unsetting GEM_HOME and GEM_PATH"
	unset GEM_HOME
	unset GEM_PATH
	
	# install ruby version from .ruby-version, skipping if already installed (-s)
	rbenv install -s
	if which rbenv > /dev/null; then eval "$(rbenv init -)"; fi
fi


if [ -e "Gemfile" ]; then
  echo  "Installing Gems";

  # install bundler gem for ruby dependency management
  gem install bundler --no-document || echo "🛑  Failed to install Bundler";
  bundle install || echo "🛑  Failed to install bundle";
fi

bundle exec fastlane install_plugins
