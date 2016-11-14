#!/usr/bin/env bash

############################
###  First time install  ###
############################

# Environment Variables
DOCKER_DEFAULT=""
SUB_DEFAULT="CADD Connect 2016 Demos"
PLAN_DEFAULT="node-todo-connect2016"

PROFILE=".bash_profile"
SETTINGS="settings.json"

function getInfo {

    # Collect docker username, project name, etc.
    # echo "Before we install..."

    # read -r -p "Enter your user name for Docker Hub (default: ${DOCKER_DEFAULT}) " DOCKER_USER
    # [ -z "${DOCKER_USER}" ] && DOCKER_USER=${DOCKER_DEFAULT}

    # read -r -p "Enter the name for your Azure subscription (default: ${SUB_DEFAULT}) " SUB_NAME
    # [ -z "${SUB_NAME}" ] && SUB_NAME=${SUB_DEFAULT}

    # read -r -p "Enter the name for your Azure plan and resources group (default: ${PLAN_DEFAULT}) " PLAN_NAME
    # [ -z "${PLAN_NAME}" ] && PLAN_NAME=${PLAN_DEFAULT}

    read -n 1 -r -p "WARNING: This script will replace your bash profile and VS Code Insiders settings. OK? " ok
    
    # Install
    case ${ok:0:1} in
        y|Y ) install ;;
        * ) exit 0 ;;
    esac

}

function install {
    
    # If we're not running from the repo, clone repo
    if ! [ -e ./install.sh ]; then
    {
        git clone git://github.com/pjmeyer/vscode-demoready
        cd vscode-demoready || exit 1;
    }
    fi

    for app in "cfprefsd" "Dock" "Docker" "Finder" "mongod" "SystemUIServer" "Terminal"; do
	killall "${app}" &> /dev/null
    done

    # Recreate bash profile, history, settings.json.
    rm -f "$HOME/$PROFILE"
    rm -f "$HOME/.bash_history"

    if [ -d "${HOME}/Library/Application\ Support/Code\ -\ Insiders/User" ]; then
    {
        rm -f "$HOME/Library/Application\ Support/Code\ -\ Insiders/User/$SETTINGS"
    } else {
        mkdir -p "${HOME}/Library/Application\ Support/Code\ -\ Insiders/User"
    }
    fi

    # Ask for the administrator password upfront
    sudo -v

    # Keep-alive: update existing `sudo` time stamp until script has finished
    while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

    # Link files from repo
    echo "Linking $PROFILE to $HOME"
    ln -s "${PWD}/${PROFILE}" "${HOME}/${PROFILE}"
    echo "Linking $SETTINGS to $HOME/Library/Application\ Support/Code\ -\ Insiders/User"
    ln -s "${PWD}/${SETTINGS}" "${HOME}/Library/Application\ Support/Code\ -\ Insiders/User/${SETTINGS}" # Sometimes fails.
    ln -s "${PWD}/.inputrc" "${HOME}/.inputrc"
    touch "$HOME/$HISTORY"

    ## if the code-insiders script doesn't exist, link the bundled one from repo
    if ! [ -e "/usr/local/bin/code-insiders" ]; then
    {
        echo "Creating VS Code shortcut..."
        chmod +x ./bin/code-insiders
        sudo ln -s "${PWD}/bin/code-insiders" "/usr/local/bin/code-insiders" # This needs to be sudo
    }
    fi

    #########
    # Set macOS defaults
    #########

    osascript -e 'tell application "System Preferences" to quit'


    # Use F-keys by default
    defaults write NSGlobalDomain com.apple.keyboard.fnState -boolean true
    
    # Disable the “Are you sure you want to open this application?” dialog
    defaults write com.apple.LaunchServices LSQuarantine -bool false

    # Never go into computer sleep mode
    sudo systemsetup -setcomputersleep Off > /dev/null

    # Disable Notification Center and remove the menu bar icon
    launchctl unload -w /System/Library/LaunchAgents/com.apple.notificationcenterui.plist 2> /dev/null
    killall NotificationCenter

    # Disable smart quotes as they’re annoying when typing code
    defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

    # Disable smart dashes as they’re annoying when typing code
    defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

    # Don’t display the annoying prompt when quitting iTerm
    defaults write com.googlecode.iterm2 PromptOnQuit -bool false

    ############################
    ## End macOS customizations
    ############################
    for app in "cfprefsd" "Dock" "Finder" "SystemUIServer" "Terminal"; do
	killall "${app}" &> /dev/null
    done
    # You will need to reboot for all these to take effect.

    # Install homebrew, if not installed
    if ! [ -e /usr/local/bin/brew ]; then
    {
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    }
    fi

    # Install Node.js, mongodb. python
    brew update
    brew upgrade
    brew install homebrew/versions/node6-lts
    brew install mongodb
    brew install python3

    # Install iTerm, Docker for Mac, Chrome
    brew tap caskroom/cask
    
    brew cask install iterm2
    brew cask install google-chrome
    brew cask install docker

    # Update Python and install AzureCLI (if not installed)
    pip3 install -U pip
    if [ ! -e /usr/local/bin/az ]; then
    {
        pip install --pre azure-cli --extra-index-url https://azureclinightly.blob.core.windows.net/packages
        export AZURE_COMPONENT_PACKAGE_INDEX_URL=https://azureclinightly.blob.core.windows.net/packages
        # Modify `az` command to call Python3
        sed -i '' 's/^python /python3 /' /usr/local/bin/az

        # No longer needed, component now installed by default
        # /usr/local/bin/az component update --add webapp –-private
    }
    fi

    # Push variables to bash profile
    # Default app name == plan name.
    # sed -i '' "s/<docker>/${DOCKER_USER}/" "${HOME}/.bash_profile"
    # sed -i '' "s/<plan>/${PLAN_NAME}/" "${HOME}/.bash_profile"
    # sed -i '' "s/<app>/${PLAN_NAME}/" "${HOME}/.bash_profile"

    echo "Done!"
    echo "Change the variables in your .bash_profile for your specific machine."
    echo "You'll also need to reboot for some macOS settings to take effect."
}

getInfo;