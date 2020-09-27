#!/usr/bin/env bash

###########################
# Custom setup post processing
# @Author: Jason Worthen
###########################

# include my library helpers for colorized echo and require_brew, etc
source ./lib_sh/echo.sh
source ./lib_sh/require.sh

# Custom application installation and configuration
action "Installing Atom packages and configuring preferences"
apm install --packages-file ./.atom/packages.txt
mkdir -p ~/.atom
cp ./.atom/config.cson ~/.atom/
ok

# Change plain-text files to use Atom or Sublime
action 'Setting atom as default editor'
# duti -s com.sublimetext.3 public.plain-text all
duti -s com.gitbub.atom public.plain-text all
ok

# Configuring iterm2
action "Configuring iTerm2"
mkdir -p ~/.dotfiles/iterm2
cp ./terminal/com.googlecode.iterm2.plist ~/.dotfiles/iterm2
ok

action "Creating working directories"
mkdir -p ~/Documents/github/
ok

# Install Office 365
action 'Downloading microsoft office (this takes a long time...)'
wget -q -O Ofc365.pkg https://go.microsoft.com/fwlink/?linkid=525133
ok

action 'Installing microsoft office (be patient again)'
sudo installer -pkg ./Ofc365.pkg -target /
rm -f ./Ofc365.pkg
ok

action "Cleaning up Dock"
sudo dockutil --removeall

dockutil --add '/Applications/Firefox.app/'
dockutil --add '/Applications/Atom.app'
dockutil --add '/Applications/iTerm.app'
dockutil --add '/Applications' --view grid --display folder --sort name --section others --allhomes
dockutil --add '~/Documents' --view list --display folder --sort name --section others --allhomes
dockutil --add '~/Downloads' --view list --display folder --sort name --section others --allhomes
