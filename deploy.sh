#!/bin/bash
TERRAFORM_INVENTORY_BIN=/usr/local/bin/terraform.py
terraform init 
terraform apply -auto-approve
ansible-playbook -i $TERRAFORM_INVENTORY_BIN play-load-node-credentials.yml
ansible-playbook -i $TERRAFORM_INVENTORY_BIN play-deploy.yml
