#!/usr/bin/env bash


###############################
###  Teardown / reset demo  ###
###############################

# (Environment Variables are exported in bash profile.)



### Teardown ###

# Kill mongo if running
#pgrep mongod | xargs kill

# Kill VS Code if running
osascript -e 'tell application "Code - Insiders" to quit'


# Remove the appservice (deprecated)
# We now reset by going into the azure portal, clearing the container variable,
# then restarting the app service.
#az appservice web delete -g "${PLAN_NAME}-rg" -n "${APP_NAME}"

# Delete docker extension
rm -rf "${HOME}/.vscode-insiders/extensions/PeterJausovec.vscode-docker-0.0.7"

# Delete VS Code
rm -rf "${HOME}/Downloads/Visual Studio Code - Insiders.app"
rm -rf "${HOME}/Downloads/VSCode-darwin-insider.zip"

# Delete directory
rm -rf "${HOME}/src/node-todo"

### Reset ###

# Pull the latest docker image
docker pull mhart/alpine-node

# Start mongo
#mongod --config /usr/local/etc/mongod.conf &
brew services restart mongodb

# Load az commands into history (deprecated)
# We now only run two of these, and they'll be copy/pasted.
# history -s "az appservice web browse -g ${PLAN_NAME}-rg -n ${APP_NAME}"
# history -s "az appservice web config container update -g ${PLAN_NAME}-rg -n ${APP_NAME} --docker-custom-image-name ${DOCKER_USER}/node-todo:latest" 
# history -s "az appservice web create -g ${PLAN_NAME}-rg -n ${APP_NAME} --plan ${PLAN_NAME}-plan" 


echo "Demo reset."