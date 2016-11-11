#!/usr/bin/env bash

############################
###  First time install  ###
############################

# Environment Variables
DOCKER_DEFAULT="chrisdias"
SUB_DEFAULT="CADD Connect 2016 Demos"
PLAN_DEFAULT="node-todo-connect2016"


PROFILE=".bash_profile"
HISTORY=".bash_history"
SETTINGS="settings.json"

function getInfo {

    # Collect docker username, project name, etc.
    echo "Before we install..."

    read -r -p "Enter your user name for Docker Hub (default: ${DOCKER_DEFAULT}) " DOCKER_USER
    [ -z "${DOCKER_USER}" ] && DOCKER_USER=${DOCKER_DEFAULT}

    read -r -p "Enter the name for your Azure subscription (default: ${SUB_DEFAULT}) " SUB_NAME
    [ -z "${SUB_NAME}" ] && SUB_NAME=${SUB_DEFAULT}

    read -r -p "Enter the name for your Azure plan and resources group (default: ${PLAN_DEFAULT}) " PLAN_NAME
    [ -z "${PLAN_NAME}" ] && PLAN_NAME=${PLAN_DEFAULT}

    read -n 1 -r -p "WARNING: This script will replace your bash profile and VS Code Insiders settings. OK? " ok
    
    # Install
    case ${ok:0:1} in
        y|Y ) install ;;
        * ) exit 0 ;;
    esac

    # Add vars into bash profile (for export). Default app name == plan name.
    # echo "export DOCKER_USER=${DOCKER_USER}" >> "${HOME}/.bash_profile"
    # echo "export PLAN_NAME=${PLAN_NAME}" >> "${HOME}/.bash_profile"
    # echo "export APP_NAME=${PLAN_NAME}" >> "${HOME}/.bash_profile"
    sed -i '' "s/<docker>/${DOCKER_USER}/" "${HOME}/.bash_profile"
    sed -i '' "s/<plan>/${PLAN_NAME}/" "${HOME}/.bash_profile"
    sed -i '' "s/<app>/${PLAN_NAME}/" "${HOME}/.bash_profile"
}

function install {
    
    # If we're not running from the repo, clone repo
    if ! [ -e ./install.sh ]; then
    {
        git clone git://github.com/pjmeyer/vscode-demoready
        cd vscode-demoready || exit 1;
    }
    fi

    # Create bash profile, history, settings.json if they don't exist.

    declare -a files=("$HOME/$PROFILE" "$HOME/$HISTORY" "$HOME/Library/Application\ Support/Code\ -\ Insiders/User/$SETTINGS")

    for i in "${files[@]}"
    do
        echo "Checking ${i}..."
        if [ -e "${i}" ]; then
            echo "Removing ${i}"
            rm -f "${i}"
        fi
    done

    if ! [ -d "${HOME}/Library/Application\ Support/Code\ -\ Insiders/User" ]; then
    {
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
    ln -s "${PWD}/${SETTINGS}" "${HOME}/Library/Application\ Support/Code\ -\ Insiders/User/${SETTINGS}"
    touch "$HOME/$HISTORY"

    ## if the code-insiders script doesn't exist, link the bundled one from repo
    if ! [ -e "/usr/local/bin/code-insiders" ]; then
    {
        echo "Creating VS Code shortcut..."
        chmod +x ./bin/code-insiders
        sudo ln -s "./bin/code-insiders" "/usr/local/bin/code-insiders" # This needs to be sudo
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

    # Start docker
    /Applications/Docker.app/Contents/MacOS/Docker &

    # Update Python and install AzureCLI
    pip3 install -U pip
    pip install --pre azure-cli --extra-index-url https://azureclinightly.blob.core.windows.net/packages
    export AZURE_COMPONENT_PACKAGE_INDEX_URL=https://azureclinightly.blob.core.windows.net/packages
    # Modify `az` command to call Python3
    sed -i '' 's/^python /python3 /' /usr/local/bin/az

    # /usr/local/bin/az component update --add webapp –-private

    # Create Azure assets
    echo "Logging in to Azure..."
    az login
    
    az account set --name "${SUB_NAME}"
    az resource group create -l westus -n "${PROJECTNAME}"-rg
    az appservice plan create -n "${PROJECTNAME}"-plan -g "${PROJECTNAME}"-rg --sku S3 --is-linux -l westus 

    # Pre-pull the docker image
    docker pull alpine-node

    echo "Done! Remember to log in to Docker (docker login)."
    echo "You'll also need to reboot for some macOS settings to take effect."
}

getInfo;