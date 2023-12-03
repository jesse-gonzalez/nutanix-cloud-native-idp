#!/bin/bash

#####
## This script will populate the .local creds and underlying environment configs for target hpoc cluster

#####
## Pre-Reqs are that it's running within Cloud Native DSL Utils Container and Secrets.yaml have already been updated

SSH_PRIVATE_KEY_PATH=$1
SSH_PUBLIC_KEY_PATH=$2
ENVIRONMENT=$3
SKIP_DELETE_PROMPT=$4

PGP_EMAIL="cloud-native-utils-$TIMESTAMP@no-reply.com"

TIMESTAMP=$(date +%s)

ARGS_LIST=($@)

## If not in docker container, exit.
if [ ! -f /.dockerenv ]; then
  echo "Must run from Cloud Native DSL Utils Docker Container. Run 'make docker-run' first"
  exit
fi

if [ ${#ARGS_LIST[@]} -lt 3 ]; then
	echo 'Usage: ./init_local_configs.sh [~/.ssh/ssh-private-key] [~/.ssh/ssh-private-key.pub] [kalm-env-hpoc-id]'
	echo 'Example: ./init_local_configs.sh .local/_common/nutanix_key .local/_common/nutanix_public_key kalm-main-10-1'
	exit
fi

if [ ! -f ./secrets.yaml ]; then
  echo "./secrets.yaml doesn't exist, copy ./secrets.yaml.example and update accordingly"
  exit
fi

## if keys are not in .local/_common path then auto-generate ssh key-pair
if [ ! -f .local/_common/nutanix_key ]; then
  echo ".local/_common/nutanix_key doesn't exist, so just auto-generating now"
  ssh-keygen -t rsa -b 4096 -f .local/_common/nutanix_key -C $PGP_EMAIL -q -N "" && mv .local/_common/nutanix_key.pub .local/_common/nutanix_public_key
fi

## if custom path, validate
if [ ! -f $SSH_PRIVATE_KEY_PATH ]; then
  echo "$SSH_PRIVATE_KEY_PATH doesn't exist, validate that path is correct"
  exit
fi

if [ ! -f $SSH_PUBLIC_KEY_PATH ]; then
  echo "$SSH_PUBLIC_KEY_PATH doesn't exist, validate that path is correct"
  exit
fi

# loop through each key and check value

echo "Validating secret values have no default values..."
if [ ! -f /usr/local/bin/shyaml ]; then
	pip install --no-cache-dir shyaml -q
fi

for i in $(cat ./secrets.yaml | shyaml keys)
do
  key_val=$(cat ./secrets.yaml | shyaml get-value $i)
  if [ "$key_val" == "required_secret" ]; then
    echo "ERROR: The following REQUIRED Password key: '$i' still has a default value of 'required_secret' set in ./secrets.yaml. please update"
    exit
  fi
  if [ "$key_val" == "required_api_key" ]; then
    echo "ERROR: The following REQUIRED API key: '$i' still has a default value of 'required_api_key' set in ./secrets.yaml. please update"
    exit
  fi
  if [ "$key_val" == "optional_secret" ]; then
    echo "INFO: The '$i' key still has 'optional_secret' set in ./secrets.yaml. Please re-run if needed."
  fi
done

echo "Initialize config/$ENVIRONMENT Directories if it doesn't exist"

if [ ! -d config/$ENVIRONMENT ]; then
	mkdir config/$ENVIRONMENT
fi

if [ ! -d .local/$ENVIRONMENT ]; then
	mkdir -p .local/$ENVIRONMENT
fi

echo "Copying ssh keys to .local/$ENVIRONMENT"

cat $SSH_PRIVATE_KEY_PATH >| .local/$ENVIRONMENT/nutanix_key
cat $SSH_PUBLIC_KEY_PATH >| .local/$ENVIRONMENT/nutanix_public_key

echo "Copying plaintext secrets.yaml to config/$ENVIRONMENT"

if [ -f config/$ENVIRONMENT/secrets.yaml ]; then
  echo "config/$ENVIRONMENT/secrets.yaml already exist, backing up and overwriting"
  mv config/$ENVIRONMENT/secrets.yaml config/$ENVIRONMENT/secrets-$TIMESTAMP.yaml
fi

cp ./secrets.yaml config/$ENVIRONMENT/secrets.yaml

echo "Generating and Exporting PGP Secret key needed to decode SOPS"

# generate pgp key for Secrets

gpg --quiet --batch --generate-key <<EOF
%echo Generating a basic OpenPGP key for Yaml Secret
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: dsl-admin
Name-Comment: Used for DSL Secrets
Name-Email: $PGP_EMAIL
Expire-Date: 0
%no-ask-passphrase
%no-protection
%commit
%echo done
EOF

PGP_FINGERPRINT=$(gpg --list-key "$PGP_EMAIL" | head -n 2 | tail -n 1 | xargs)

if [ -f .local/$ENVIRONMENT/sops_gpg_key ]; then
  echo ".local/$ENVIRONMENT/sops_gpg_key already exist, backing up and overwriting"
  mv .local/$ENVIRONMENT/sops_gpg_key .local/$ENVIRONMENT/sops_gpg_key-$TIMESTAMP
fi

# exporting key
gpg --quiet --export-secret-key --armor "$PGP_EMAIL" > .local/$ENVIRONMENT/sops_gpg_key

echo "Setting fingerprint: $PGP_FINGERPRINT in file config/$ENVIRONMENT/.sops.yaml"

if [ -f config/$ENVIRONMENT/.sops.yaml ]; then
  echo "config/$ENVIRONMENT/.sops.yaml already exist, backing up and overwriting"
  mv config/$ENVIRONMENT/.sops.yaml config/$ENVIRONMENT/.sops-$TIMESTAMP.yaml
fi

cat <<EOF | tee config/$ENVIRONMENT/.sops.yaml
creation_rules:
    - pgp: '$(echo $PGP_FINGERPRINT)'
EOF

echo "Encrypting config/$ENVIRONMENT/secrets.yaml with fingerprint: $PGP_FINGERPRINT in file config/$ENVIRONMENT/.sops.yaml"

sops --encrypt --in-place --pgp $PGP_FINGERPRINT config/$ENVIRONMENT/secrets.yaml

# OVERRIDING YAML and PGP KEY PATH if _common sops_gpg_key is unavailable

echo "Setting config/$ENVIRONMENT/.env with Override Paths"

if [ -f config/$ENVIRONMENT/.env ]; then
  echo "config/$ENVIRONMENT/.env already exist, backing up and updating"
  cp config/$ENVIRONMENT/.env config/$ENVIRONMENT/.env-$TIMESTAMP
fi

touch config/$ENVIRONMENT/.env
grep -i PGP_KEY_PATH config/$ENVIRONMENT/.env && sed -i "s/PGP_KEY_PATH =.*/PGP_KEY_PATH = .local\/$\{ENVIRONMENT\}\/sops_gpg_key/g" config/$ENVIRONMENT/.env || echo -e "PGP_KEY_PATH = .local/\${ENVIRONMENT}/sops_gpg_key" >> config/$ENVIRONMENT/.env;
grep -i YAML_SECRETS_PATH config/$ENVIRONMENT/.env && sed -i "s/YAML_SECRETS_PATH =.*/YAML_SECRETS_PATH = config\/$\{ENVIRONMENT\}\/secrets.yaml/g" config/$ENVIRONMENT/.env || echo -e "YAML_SECRETS_PATH = config/\${ENVIRONMENT}/secrets.yaml" >> config/$ENVIRONMENT/.env;

#echo "PGP_KEY_PATH = .local/$ENVIRONMENT/sops_gpg_key" >> config/$ENVIRONMENT/.env
#echo "YAML_SECRETS_PATH = config/$ENVIRONMENT/secrets.yaml" >> config/$ENVIRONMENT/.env

delete_prompt="y"

if [ "$SKIP_DELETE_PROMPT" != "true" ]; then
  read -p "Would you like to delete plaintext ./secrets.yaml? (y or n): " delete_prompt
fi

if [ "$delete_prompt" == "y" ]; then
  echo "Deleting ./secrets.yaml"
  rm ./secrets.yaml
elif [ "$delete_prompt" == "n" ]; then
  echo "Copying & renaming ./secrets.yaml to ./secrets-$ENVIRONMENT-$TIMESTAMP.yaml"
  cp ./secrets.yaml ./secrets-$ENVIRONMENT-$TIMESTAMP.yaml
else
  echo "Invalid Entry. please type 'y' or 'n'."
  read -p "Would you like to delete manually created ./secrets.yaml? (y or n): " delete_prompt
fi

echo "SUCCESS: Decrypt secrets using following command 'sops --decrypt config/$ENVIRONMENT/secrets.yaml'"