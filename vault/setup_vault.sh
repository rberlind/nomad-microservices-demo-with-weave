#!/bin/bash

# Script to setup of Vault for the Nomad/Consul demo
echo "Before running this, you must export your"
echo "AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY keys"
echo "and your VAULT_ADDR and VAULT_TOKEN environment variables."

# Set up the Vault AWS Secrets Engine
echo "Setting up the AWS Secrets Engine"
echo "Enabling the AWS secrets engine at path aws-tf"
vault secrets enable -path=aws-tf aws
echo "Providing Vault with AWS keys that can create other keys"
vault write aws-tf/config/root access_key=$AWS_ACCESS_KEY_ID secret_key=$AWS_SECRET_ACCESS_KEY
echo "Configuring default and max leases on generated keys"
vault write aws-tf/config/lease lease=1h lease_max=24h
echo "Creating the AWS deploy role and assigning policy to it"
vault write aws-tf/roles/deploy policy=@aws-policy.json

# Setup the Vault SSH secret backend
# We are using this just to generate a root password
# for the MySQL database used by the catalogue-db database
echo "Setting up the Vault SSH secret backend"
vault secrets enable -path=ssh-nomad ssh
echo "Setting up the otp_nomad role for SSH"
vault write ssh-nomad/roles/otp_nomad key_type=otp default_user=root cidr_list=172.17.0.0/24
echo "Writing the ssh_policy.hcl to Vault"
vault policy write ssh_policy ssh_policy.hcl

# Setup Vault policy/role for Nomad
echo "Setting up Vault policy and role for Nomad"
echo "Writing nomad-server-policy.hcl to Vault"
vault policy write nomad-server nomad-server-policy.hcl
echo "Writing nomad-cluster-role.json to Vault"
vault write auth/token/roles/nomad-cluster @nomad-cluster-role.json
