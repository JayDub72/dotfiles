#!/usr/bin/env bash

###########################
# Custom setup post processing
# @Author: Jason Worthen
###########################

# include my library helpers for colorized echo and require_brew, etc
source ./lib_sh/echo.sh
source ./lib_sh/require.sh

# Custom application installation and configuration
bot "Installing Atom packages and configuring preferences"
apm install --packages-file ./.atom/packages.txt
mkdir -p ~/.atom
cp ./.atom/config.cson ~/.atom/

# Change plain-text files to use Atom or Sublime
action 'setting atom as default editor'
# duti -s com.sublimetext.3 public.plain-text all
duti -s com.gitbub.atom public.plain-text all
ok

bot "Creating working directories"
mkdir -p ~/Documents/github/

# Install Office 365
action 'downloading microsoft office (this takes a long time...)'
wget -q -O Ofc365.pkg https://go.microsoft.com/fwlink/?linkid=525133
ok

action 'installing microsoft office (be patient again)'
sudo installer -pkg ./Ofc365.pkg -target /
ok

action "Cleaning up Dock"
sudo dockutil --remove '/Applications/Launchpad.app'
sudo dockutil --remove '/Applications/Safari.app'
sudo dockutil --remove '/Applications/Mail.app'
sudo dockutil --remove '/Applications/FaceTime.app'
sudo dockutil --remove '/Applications/Maps.app'
sudo dockutil --remove '/Applications/Contacts.app'
sudo dockutil --remove '/Applications/Reminders.app'
sudo dockutil --remove '/Applications/Music.app'
sudo dockutil --remove '/Applications/Podcast.app'
sudo dockutil --remove '/Applications/TV.app'
sudo dockutil --remove '/Applications/News.app'
sudo dockutil --remove '/Applications/Keynote.app'
sudo dockutil --remove '/Applications/Numbers.app'
sudo dockutil --remove '/Applications/App Store.app'
sudo dockutil --remove '/Applications/System Preferences.app'
sudo dockutil --remove '/Applications/TV.app'

dockutil --add '/Applications/Firefox.app/'
dockutil --add '/Applications/Calendar.app/'
dockutil --add '/Applications/Messages.app/'
dockutil --add '/Applications/Notes.app/'
dockutil --add '/Applications/Spotify.app'
dockutil --add '/Applications/Atom.app'
dockutil --add '/Applications/iTerm.app'
dockutil --add '/Applications/Photos.app'
dockutil --add '/Applications' --view grid --display folder --sort name --section others --allhomes
dockutil --add '~/Documents' --view list --display folder --sort name --section others --allhomes
dockutil --add '~/Downloads' --view list --display folder --sort name --section others --allhomes

rm -f ./Ofc365.pkg
