#!/bin/bash
## Ubuntu Server 20.04 LTS or 18.04 LTS  (HVM) for full functionality size 2xlarge 
## Microkubernetes 1.15, Keptn 6.1 with Istio 1.5, Helm 1.2, Docker, Registry, Dynatrace OneAgent and Dynatrace ActiveGate

## ----  Define variables ----
LOGFILE='/tmp/install.log'
chmod 775 $LOGFILE
pipe_log=true

# The installation will look for this file locally, if not found it will pull it form github.
FUNCTIONS_FILE='functions.sh'

# The user to run the commands from. Will be overwritten when executing this shell with sudo 
USER="ubuntu"

# create_workshop_user=true (will clone the home directory from USER and allow SSH login with text password )
NEWPWD="dynatrace"
NEWUSER="dynatrace"

# ****  Define Dynatrace Environment **** 
# Sample: https://{your-domain}/e/{your-environment-id} for managed or https://{your-environment-id}.live.dynatrace.com for SaaS
TENANT=
PAASTOKEN=
APITOKEN=

## Get/Set EC2 Instnace ID, Elastic IP instance, and 'aws configure' data
EC2_INSTANCE_ID="`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`"
ELASTIC_ALLOCATION_ID=
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
REGION=us-east-2
OUTPUT=json

## install AWS CLI
sudo apt install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

## Configure AWS CLI
mkdir ~/.aws
touch ~/.aws/credentials
echo "[default]" >> ~/.aws/credentials
echo "aws_access_key_id=$AWS_ACCESS_KEY_ID" >> ~/.aws/credentials
echo "aws_secret_access_key=$AWS_SECRET_ACCESS_KEY" >> ~/.aws/credentials
touch ~/.aws/config
echo "[default]" >> ~/.aws/config
echo "region=$REGION" >> ~/.aws/config
echo "output=$OUTPUT" >> ~/.aws/config

## associate ElasticIP with EC2 Instance
aws ec2 associate-address --instance-id $EC2_INSTANCE_ID --allocation-id 	$ELASTIC_ALLOCATION_ID

# Set your custom domain e.g for an internal machine like 192.168.0.1.nip.io
# So Keptn and all other services are routed and exposed properly via the Ingress Gateway
# if no DOMAIN is setted, the public IP of the machine will be converted to a magic nip.io domain   
DOMAIN=

# **** Installation Versions **** 
ISTIO_VERSION=1.5.1
HELM_VERSION=2.12.3
CERTMANAGER_VERSION=0.14.0
KEPTN_VERSION=0.6.1
KEPTN_DT_SERVICE_VERSION=0.6.2
KEPTN_DT_SLI_SERVICE_VERSION=0.3.1
KEPTN_EXAMPLES_BRANCH=0.6.1
TEASER_IMAGE="shinojosa/nginxacm"
KEPTN_BRIDGE_IMAGE="keptn/bridge2:20200326.0744"
MICROK8S_CHANNEL="1.15/stable"

## ----  Write all to the logfile ----
if [ "$pipe_log" = true ] ; then
  echo "Piping all output to logfile $LOGFILE"
  echo "Type 'less +F $LOGFILE' for viewing the output of installation on realtime"
  echo "If you did not send the job to the background, type \"CTRL + Z\" and \"bg\""
  echo "CTRL + Z (for pausing this job)"
  echo "then"
  echo "bg (for resuming back this job and send it to the background)"
  # Saves file descriptors so they can be restored to whatever they were before redirection or used 
  # themselves to output to whatever they were before the following redirect.
  exec 3>&1 4>&2
  # Restore file descriptors for particular signals. Not generally necessary since they should be restored when the sub-shell exits.
  trap 'exec 2>&4 1>&3' 0 1 2 3
  # Redirect stdout to file log.out then redirect stderr to stdout. Note that the order is important when you 
  # want them going to the same file. stdout must be redirected before stderr is redirected to stdout.
  exec 1>$LOGFILE 2>&1
else
  echo "Not piping stdout stderr to the logfile, writing the installation to the console"
fi

# Load functions after defining the variables & versions
if [ -f "$FUNCTIONS_FILE" ]; then
    echo "The functions file $FUNCTIONS_FILE exists locally, loading functions from it."
else 
    echo "The functions file $FUNCTIONS_FILE does not exist, getting it from github."
    curl -o functions.sh https://raw.githubusercontent.com/keptn-sandbox/keptn-in-a-box/master/functions.sh
fi

# Comfortable function for setting the sudo user.
if [ -n "${SUDO_USER}" ] ; then
  USER=$SUDO_USER
fi
echo "running sudo commands as $USER"

# Wrapper for runnig commands for the real owner and not as root
alias bashas="sudo -H -u ${USER} bash -c"
# Expand aliases for non-interactive shell
shopt -s expand_aliases

# --- Loading the functions in the current shell
source $FUNCTIONS_FILE


# --- Enable the installation Modules --- 
# Uncomment for installing the Default 
#installationModulesDefault

# - Uncomment below for installing the minimal setup
#installationModulesMinimal

# - Uncomment below for installing all features
installationModulesFull

# -- Override a module like for example verbose output of all commands
#verbose_mode=true
# -- or install cert manager 
certmanager_install=true
certmanager_enable=true

# *** Do Installation 
doInstallation
