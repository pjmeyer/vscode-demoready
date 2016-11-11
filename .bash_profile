

# .bash_profile
# Customized for demoing

# Export Environment variables
export AZURE_COMPONENT_PACKAGE_INDEX_URL=https://azureclinightly.blob.core.windows.net/packages
export DOCKER_USER=<docker>
export PLAN_NAME=<plan>
export APP_NAME=<app>

# Enable Azure CLI completions 
source /usr/local/bin/az.completion.sh 

# Common aliases
alias cd..='cd ..' 
alias dir='ls -l' 
alias ..='cd ..' 

# Custom prompt
export PS1='\[\033[1;94m\]\w$\[\033[0m\] ' 
