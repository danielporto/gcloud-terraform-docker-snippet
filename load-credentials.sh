
# load-credentials.sh 
# author Daniel Porto - daniel.porto@gmail.com 
#
# This script reads a json credentials file downloaded from google cloud platform
# and loads the respective environment variables required by both ansible and terraform
# to login and deploy tasks
#
# Do not change this file. Any variable should be added to envs.sh

# 
alias help='
    echo "Bootstrap terraform with:              \$ terraform init";\
    echo "Deploy the configuration with          \$ terraform apply";\
    echo "Cleanup deployment                     \$ terraform destroy";\
    echo "To list ansible dynamic inventory      \$ ansibleti-inventory --list";\
    echo "To install sshkeys of remote hosts run \$ ansibleti-playbook keyscan.yml";\
    echo "Ping hosts of terraform state:         \$ ansibleti all -m ping" ;\
    echo "Send command to nodes:                 \$ ansibleti all -m shell -a \"whoami\" "
    echo "Check other aliases with:              \$ alias ";\
    echo "Connect to instances:                  \$ sshgcp instance_IP";\
    echo "Connect to instances with: \$ gcloud compute --project "${TF_VAR_GCPProjectID}" ssh --zone "${ZONE}" instance_name";
'

if [ -f "${TF_VAR_GCPCredentialsFile}" ]; then
    export TF_VAR_GCPProjectID=$(egrep project_id ${TF_VAR_GCPCredentialsFile} | sed -e 's/  "project_id": "//g' -e 's/",//g')
    export TF_VAR_GCPEMail=$(egrep client_email ${TF_VAR_GCPCredentialsFile} | sed -e 's/  "client_email": "//g' -e 's/",//g')
    export TF_VAR_GCPClientID=$(egrep client_id ${TF_VAR_GCPCredentialsFile} | sed -e 's/  "client_id": "//g' -e 's/",//g')
    export ZONE=`awk '/GCPRegion/,/default/' terraform-vars.tf | egrep default | awk -F '["]' '{print $2 }'`

    echo "Logging in with a service account."
    gcloud auth activate-service-account --key-file ${TF_VAR_GCPCredentialsFile}
    echo "Setting the project: ${TF_VAR_GCPProjectID}"
    gcloud config set project ${TF_VAR_GCPProjectID}
    
    echo "Enable Google cloud APIs y/N? This is required once per project. Timeout 5s...."
    read -t 5 answer
    if [[ "$answer" =~ "[yY]" ]]; then
        echo "Enabling APIs (it can take a while...)"
        gcloud services enable cloudresourcemanager.googleapis.com  |& egrep -v "successfully" | egrep -v "Waiting for"  | egrep -v "gcloud services operations describe operations"  
        echo "25% done......"
        gcloud services enable cloudbilling.googleapis.com |& egrep -v "successfully" | egrep -v "Waiting for"  | egrep -v "gcloud services operations describe operations"  
        echo "50% done...."
        gcloud services enable iam.googleapis.com |& egrep -v "successfully" | egrep -v "Waiting for"  | egrep -v "gcloud services operations describe operations"  
        echo "75% done..."
        gcloud services enable compute.googleapis.com |& egrep -v "successfully" | egrep -v "Waiting for"  | egrep -v "gcloud services operations describe operations"  
        echo "100% done"
    fi

    # create ssh keys for the project if it doesnt exist
    if [ ! -f "$HOME/.ssh/google_compute_engine" ]; then
        echo "Creating ssh keys"
        gcloud compute config-ssh --quiet --project ${TF_VAR_GCPProjectID}
    else
        echo "SSH keys already exists, skipping its generation."
    fi
    
    alias sshgcp="ssh -i $HOME/.ssh/google_compute_engine"
    
    echo "Creating aliases for ansible and ssh"
    TERRAFORM_INVENTORY_BIN=/usr/local/bin/terraform.py
    alias terraform_inventory="$TERRAFORM_INVENTORY_BIN"
    alias ansibleti="ansible -i $TERRAFORM_INVENTORY_BIN" 
    alias ansibleti-playbook="ansible-playbook -i $TERRAFORM_INVENTORY_BIN"
    alias ansibleti-inventory="ansible-inventory -i $TERRAFORM_INVENTORY_BIN" 
    echo "-------------------------------------------------------"
    echo "Project id loaded ${TF_VAR_GCPProjectID}"
    echo "Default zone: ${ZONE}"
    echo "Credentials loaded from json: ${TF_VAR_GCPCredentialsFile}"
    if [ -f "$HOME/.ssh/google_compute_engine" ]; then
        echo "Ssh keys genereted at $HOME/.ssh/google_compute_engine" 
    else
        echo "ERROR, compute engine keys not generated"
        exit -1
    fi
    echo "-------------------------------------------------------"
    echo "Ready to go!"
    # print help mensage with instructions
    help;
    echo "Run command \"help\" to see this message again."
    echo "-------------------------------------------------------"

else
    echo "-------------------------------------------------------"
    echo " 1 - Credentials file not found. Please download it to ${TF_VAR_GCPCredentialsFile}," 
    echo " 2 - Run: source load-credentials.sh"
    echo "-------------------------------------------------------"

fi 