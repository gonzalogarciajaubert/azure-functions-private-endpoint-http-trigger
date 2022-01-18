#!/bin/bash

COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
COLOR_CYAN='\033[0;36m'

# Variables
resourceGroupName="<your-resource-group-name>"
location="<your-favorite-location>"
deploy=1

# ARM template and parameters files
template="../templates/azuredeploy.json"
parameters="../templates/azuredeploy.parameters.json"

# SubscriptionId of the current subscription
subscriptionId=$(az account show --query id --output tsv)
subscriptionName=$(az account show --query name --output tsv)

# Check if the resource group already exists
createResourceGroup() {
    local resourceGroupName=$1
    local location=$2

    # Parameters validation
    if [[ -z $resourceGroupName ]]; then
        echo -e "${COLOR_RED} 🧨 The resource group name parameter cannot be null"
        exit
    fi

    if [[ -z $location ]]; then
        echo -e "${COLOR_RED} 🧨 The location parameter cannot be null"
        exit
    fi

    echo -e "${COLOR_CYAN} ⏳ Checking if [$resourceGroupName] resource group actually exists in the [$subscriptionName] subscription..."

    if ! az group show --name "$resourceGroupName" &>/dev/null; then
        echo -e "${COLOR_CYAN} ⏳ No [$resourceGroupName] resource group actually exists in the [$subscriptionName] subscription"
        echo -e "${COLOR_CYAN} ⏳ Creating [$resourceGroupName] resource group in the [$subscriptionName] subscription..."

        # Create the resource group
        if az group create --name "$resourceGroupName" --location "$location" 1>/dev/null; then
            echo -e "${COLOR_GREEN} ✨🧙✨ [$resourceGroupName] resource group successfully created in the [$subscriptionName] subscription"
        else
            echo -e "${COLOR_RED} 🧨 Failed to create [$resourceGroupName] resource group in the [$subscriptionName] subscription"
            exit
        fi
    else
        echo "[$resourceGroupName] resource group already exists in the [$subscriptionName] subscription"
    fi
}

# Validate the ARM template
validateTemplate() {
    local resourceGroupName=$1
    local template=$2
    local parameters=$3
    local arguments=$4

    # Parameters validation
    if [[ -z $resourceGroupName ]]; then
        echo -e "${COLOR_RED} 🧨 The resource group name parameter cannot be null"
    fi

    if [[ -z $template ]]; then
        echo -e "${COLOR_RED} 🧨 The template parameter cannot be null"
    fi

    if [[ -z $parameters ]]; then
        echo -e "${COLOR_RED} 🧨 The parameters parameter cannot be null"
    fi

    echo -e "${COLOR_CYAN} ⏳ Validating [$template] ARM template..."

    if [[ -z $arguments ]]; then
        error=$(az deployment group validate \
            --resource-group "$resourceGroupName" \
            --template-file "$template" \
            --parameters "$parameters" \
            --query error \
            --output json)
    else
        error=$(az deployment group validate \
            --resource-group "$resourceGroupName" \
            --template-file "$template" \
            --parameters "$parameters" \
            --arguments $arguments \
            --query error \
            --output json)
    fi

    if [[ -z $error ]]; then
        echo -e "${COLOR_GREEN} ✨🧙✨ [$template] ARM template successfully validated"
    else
        echo -e "${COLOR_RED} 🧨 Failed to validate the [$template] ARM template"
        echo "$error"
        exit 1
    fi
}

# Deploy ARM template
deployTemplate() {
    local resourceGroupName=$1
    local template=$2
    local parameters=$3
    local arguments=$4

    # Parameters validation
    if [[ -z $resourceGroupName ]]; then
        echo -e "${COLOR_RED} 🧨 The resource group name parameter cannot be null"
        exit
    fi

    if [[ -z $template ]]; then
        echo -e "${COLOR_RED} 🧨 The template parameter cannot be null"
        exit
    fi

    if [[ -z $parameters ]]; then
        echo -e "${COLOR_RED} 🧨 The parameters parameter cannot be null"
        exit
    fi

    if [ $deploy != 1 ]; then
        return
    fi

    # Deploy the ARM template
    echo -e "${COLOR_CYAN} ⏳ Deploying [$template$] ARM template..."

    if [[ -z $arguments ]]; then
         az deployment group create --verbose \
            --resource-group $resourceGroupName \
            --template-file $template \
            --parameters $parameters 1>/dev/null
    else
         az deployment group create --verbose  \
            --resource-group $resourceGroupName \
            --template-file $template \
            --parameters $parameters \
            --parameters $arguments 1>/dev/null
    fi

    if [[ $? == 0 ]]; then
        echo -e "${COLOR_GREEN} ✨🧙✨ [$template$] ARM template successfully provisioned"
    else
        echo -e "${COLOR_RED} 🧨 Failed to provision the [$template$] ARM template"
        az group delete -n $resourceGroupName --subscription $subscriptionId
        exit -1
    fi
}

# Create Resource Group
createResourceGroup \
    "$resourceGroupName" \
     "$location"

# Validate ARM Template
validateTemplate \
    "$resourceGroupName" \
    "$template" \
    "$parameters"

# Deploy ARM Template
deployTemplate \
    "$resourceGroupName" \
    "$template" \
    "$parameters"
