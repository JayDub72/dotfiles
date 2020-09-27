#!/usr/bin/env bash

#TODO: update after macOS Catalina, default mac shell: bash is changing to zsh

###########################
# This script installs the dotfiles and runs all other system configuration scripts
# @author Adam Eivy
###########################

# include my library helpers for colorized echo and require_brew, etc
source ./lib_sh/echo.sh
source ./lib_sh/require.sh

bot "Preparing system..."

# Do we need to ask for sudo password or is it already passwordless?
grep -q 'NOPASSWD:     ALL' /etc/sudoers.d/$LOGNAME > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "no sudoer file"
  sudo -v

  # Keep-alive: update existing sudo time stamp until the script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

  bot "Do you want to setup this machine to allow you to run sudo without a password?\nPlease read here to see what I am doing:\nhttp://wiki.summercode.com/sudo_without_a_password_in_mac_os_x \n"

  read -r -p "Make sudo passwordless? [y|N] " response

  if [[ $response =~ (yes|y|Y) ]];then
      if ! grep -q "#includedir /private/etc/sudoers.d" /etc/sudoers; then
        echo '#includedir /private/etc/sudoers.d' | sudo tee -a /etc/sudoers > /dev/null
      fi
      echo -e "Defaults:$LOGNAME    !requiretty\n$LOGNAME ALL=(ALL) NOPASSWD:     ALL" | sudo tee /etc/sudoers.d/$LOGNAME
      echo "You can now run sudo commands without password!"
  fi
fi

# ###########################################################
# /etc/hosts -- spyware/ad blocking
# ###########################################################
read -r -p "Overwrite /etc/hosts with the ad-blocking hosts file from someonewhocares.org? (from ./config/hosts file) [y|N] " response
if [[ $response =~ (yes|y|Y) ]];then
    sudo cp /etc/hosts /etc/hosts.backup
    sudo cp ./config/hosts /etc/hosts
    bot "Your /etc/hosts file has been updated. Last version is saved in /etc/hosts.backup"
else
    ok "skipped";
fi

# ###########################################################
# Git Config
# ###########################################################
bot "Time to update the .gitconfig with your user info:"
grep 'user = GITHUBUSER' ./homedir/.gitconfig > /dev/null 2>&1
if [[ $? = 0 ]]; then
    read -r -p "What is your git username? " githubuser

  fullname=`osascript -e "long user name of (system info)"`

  if [[ -n "$fullname" ]];then
    lastname=$(echo $fullname | awk '{print $2}');
    firstname=$(echo $fullname | awk '{print $1}');
  fi

  if [[ -z $lastname ]]; then
    lastname=`dscl . -read /Users/$(whoami) | grep LastName | sed "s/LastName: //"`
  fi
  if [[ -z $firstname ]]; then
    firstname=`dscl . -read /Users/$(whoami) | grep FirstName | sed "s/FirstName: //"`
  fi
  email=`dscl . -read /Users/$(whoami)  | grep EMailAddress | sed "s/EMailAddress: //"`

  if [[ ! "$firstname" ]]; then
    response='n'
  else
    echo -e "I see that your full name is $COL_YELLOW$firstname $lastname$COL_RESET"
    read -r -p "Is this correct? [Y|n] " response
  fi

  if [[ $response =~ ^(no|n|N) ]]; then
    read -r -p "What is your first name? " firstname
    read -r -p "What is your last name? " lastname
  fi
  fullname="$firstname $lastname"

  bot "Great $fullname, "

  if [[ ! $email ]]; then
    response='n'
  else
    echo -e "The best I can make out, your email address is $COL_YELLOW$email$COL_RESET"
    read -r -p "Is this correct? [Y|n] " response
  fi

  if [[ $response =~ ^(no|n|N) ]]; then
    read -r -p "What is your email? " email
    if [[ ! $email ]];then
      error "you must provide an email to configure .gitconfig"
      exit 1
    fi
  fi

  running "replacing items in .gitconfig with your info ($COL_YELLOW$fullname, $email, $githubuser$COL_RESET)"

  # test if gnu-sed or MacOS sed

  sed -i "s/GITHUBFULLNAME/$firstname $lastname/" ./homedir/.gitconfig > /dev/null 2>&1 | true
  if [[ ${PIPESTATUS[0]} != 0 ]]; then
    echo
    running "looks like you are using MacOS sed rather than gnu-sed, accommodating"
    sed -i '' "s/GITHUBFULLNAME/$firstname $lastname/" ./homedir/.gitconfig
    sed -i '' 's/GITHUBEMAIL/'$email'/' ./homedir/.gitconfig
    sed -i '' 's/GITHUBUSER/'$githubuser'/' ./homedir/.gitconfig
    ok
  else
    echo
    bot "looks like you are already using gnu-sed. woot!"
    sed -i 's/GITHUBEMAIL/'$email'/' ./homedir/.gitconfig
    sed -i 's/GITHUBUSER/'$githubuser'/' ./homedir/.gitconfig
  fi
fi

# ###########################################################
# Install non-brew various tools (PRE-BREW Installs)
# ###########################################################
bot "Validating that XCode command line tools are installed properly."
if ! xcode-select --print-path &> /dev/null; then

    # Prompt user to install the XCode Command Line Tools
    xcode-select --install &> /dev/null

    # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    # Wait until the XCode Command Line Tools are installed
    until xcode-select --print-path &> /dev/null; do
        sleep 5
    done

    print_result $? ' XCode Command Line Tools Installed'

    # Prompt user to agree to the terms of the Xcode license
    # https://github.com/alrra/dotfiles/issues/10
    sudo xcodebuild -license
    print_result $? 'Agree with the XCode Command Line Tools licence'

fi

# ###########################################################
# install homebrew (CLI Packages)
# ###########################################################
running "checking homebrew..."
brew_bin=$(which brew) 2>&1 > /dev/null
if [[ $? != 0 ]]; then
  action "installing homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  if [[ $? != 0 ]]; then
    error "unable to install homebrew, script $0 abort!"
    exit 2
  fi
  brew bundle
  brew install romkatv/powerlevel10k/powerlevel10k
  brew analytics off
else
  ok
  bot "Homebrew"
  read -r -p "run brew update && upgrade? [y|N] " response
  if [[ $response =~ (y|yes|Y) ]]; then
    action "updating homebrew..."
    brew update
    ok "homebrew updated"
    action "upgrading brew packages..."
    brew upgrade
    ok "brews upgraded"
  else
    ok "skipped brew package upgrades."
  fi
fi

# Just to avoid a potential bug
mkdir -p ~/Library/Caches/Homebrew/Formula
brew doctor

# set zsh as the user login shell
CURRENTSHELL=$(dscl . -read /Users/$USER UserShell | awk '{print $2}')
if [[ "$CURRENTSHELL" != "/usr/local/bin/zsh" ]]; then
  action "setting newer homebrew zsh (/usr/local/bin/zsh) as your shell (password required)"
  # sudo bash -c 'echo "/usr/local/bin/zsh" >> /etc/shells'
  # chsh -s /usr/local/bin/zsh
  sudo dscl . -change /Users/$USER UserShell $SHELL /usr/local/bin/zsh > /dev/null 2>&1
  ok
fi

# if [[ ! -d "./oh-my-zsh/custom/themes/powerlevel9k" ]]; then
#   git clone https://github.com/bhilburn/powerlevel9k.git oh-my-zsh/custom/themes/powerlevel9k
# fi

bot "Dotfiles Setup"
read -r -p "Do you want to create symlinks in your home diretory for the dotfiles? [y|N] " response
if [[ $response =~ (y|yes|Y) ]]; then
  bot "creating symlinks for project dotfiles..."
  pushd homedir > /dev/null 2>&1
  now=$(date +"%Y.%m.%d.%H.%M.%S")

  for file in .*; do
    if [[ $file == "." || $file == ".." ]]; then
      continue
    fi
    running "~/$file"
    # if the file exists:
    if [[ -e ~/$file ]]; then
        mkdir -p ~/.dotfiles_backup/$now
        mv ~/$file ~/.dotfiles_backup/$now/$file
        echo "backup saved as ~/.dotfiles_backup/$now/$file"
    fi
    # symlink might still exist
    unlink ~/$file > /dev/null 2>&1
    # create the link
    ln -s ~/.dotfiles/homedir/$file ~/$file
    echo -en '\tlinked';ok
  done

  popd > /dev/null 2>&1
fi

# bot "VIM Setup"
# read -r -p "Do you want to install vim plugins now? [y|N] " response
# if [[ $response =~ (y|yes|Y) ]];then
#   bot "Installing vim plugins"
  # cmake is required to compile vim bundle YouCompleteMe
  # require_brew cmake
#   vim +PluginInstall +qall > /dev/null 2>&1
#   ok
# else
#   ok "skipped. Install by running :PluginInstall within vim"
# fi

bot "Custom appliction install and configuration"
read -r -p "Do you want to install custom applications and configure them? [y|N] " response
if [[ $response =~ (y|yes|Y) ]]; then
  bot "Installing & Configuring specific applications..."
  source ./appinstall.sh
fi

bot "Setup SSH keys"
read -r -p "Do you want to configure SSH now? [y|N] " response
if [[ $response =~ (y|yes|Y) ]]; then
  bot "Configuring SSH keys..."
  ssh-keygen -t rsa -b 4096 -C "jason@worthen.org"
  eval "$(ssh-agent -s)"
  cp ./ssh/config ~/.ssh/config
  /usr/bin/ssh-add -K ~/.ssh/id_rsa
  pbcopy < ~/.ssh/id_rsa.pub

  bot "SSH key generated and in clipboard.  Log in to github and enable authentication."
fi

running "Cleanup homebrew"
brew cleanup --force > /dev/null 2>&1
rm -f -r /Library/Caches/Homebrew/* > /dev/null 2>&1
ok

bot "macOS Configuration"
read -r -p "Do you want to install custom applications and configure them? [y|N] " response
if [[ $response =~ (y|yes|Y) ]]; then
  bot "Installing & Configuring specific applications..."
  source ./macos.sh
fi

bot "All done."
