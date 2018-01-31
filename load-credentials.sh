
# load-credentials.sh 
# author Daniel Porto - daniel.porto@gmail.com 
#
# This script reads a json credentials file downloaded from google cloud platform
# and loads the respective environment variables used by both ansible and terraform
# to login and deploy tasks
#
# Do not change this file. Any variable should be added to envs.sh

if [ -f "${TF_VAR_GCPCredentialsFile}" ]; then
    export TF_VAR_GCPProjectID=$(grep project_id ${TF_VAR_GCPCredentialsFile} | sed -e 's/  "project_id": "//g' -e 's/",//g')
    export TF_VAR_GCPEMail=$(grep client_email ${TF_VAR_GCPCredentialsFile} | sed -e 's/  "client_email": "//g' -e 's/",//g')
    export TF_VAR_GCPClientID=$(grep client_id ${TF_VAR_GCPCredentialsFile} | sed -e 's/  "client_id": "//g' -e 's/",//g')
    export ZONE=`awk '/GCPRegion/,/default/' terraform-vars.tf | grep default | awk -F '["]' '{print $2 }'`

    echo "Setting the project: ${TF_VAR_GCPProjectID}"
    gcloud config set project ${TF_VAR_GCPProjectID}
    echo "Enabling APIs (it can take a while...)"
    gcloud services enable cloudresourcemanager.googleapis.com  |& grep -v "successfully" | grep -v "Waiting for"  | grep -v "gcloud services operations describe operations"  
    echo "25% done......"
    gcloud services enable cloudbilling.googleapis.com |& grep -v "successfully" | grep -v "Waiting for"  | grep -v "gcloud services operations describe operations"  
    echo "50% done...."
    gcloud services enable iam.googleapis.com |& grep -v "successfully" | grep -v "Waiting for"  | grep -v "gcloud services operations describe operations"  
    echo "75% done..."
    gcloud services enable compute.googleapis.com |& grep -v "successfully" | grep -v "Waiting for"  | grep -v "gcloud services operations describe operations"  
    echo "100% done"

    echo "Creating ssh keys"
    gcloud compute config-ssh --quiet --project ${TF_VAR_GCPProjectID}
    alias sshgcp='gcloud compute --project "${TF_VAR_GCPProjectID}" ssh --zone "${ZONE}"' 
    echo "-------------------------------------------------------"
    echo "Project id loaded ${TF_VAR_GCPProjectID}"
    echo "Default zone: ${ZONE}"
    echo "Credentials loaded from json: ${TF_VAR_GCPCredentialsFile}"
    if [ -f "$HOME/.ssh/google_compute_engine" ]; then
        echo "Ssh keys genereted at $HOME/.ssh/google_compute_engine" 
        echo "Connect to instances with: 'sshgcp instance'"
    else
        echo "ERROR, compute engine keys not generated"
    fi
    echo "-------------------------------------------------------"
    echo "Ready to go, bootstrap terraform with: terraform init"
else
    echo "-------------------------------------------------------"
    echo "1 - Credentials file not found. Please download it to ${TF_VAR_GCPCredentialsFile}," 
    echo "2 - Then log in: gcloud auth login"
    echo "3 - Finally run: source load-credentials.sh"
    echo "-------------------------------------------------------"

fi 