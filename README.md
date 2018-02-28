
# Description
This is a simple working example of how to deploy a container in google compute engine
using terraform and docker.

# Requirements 
* A google project with owner access rights.
* Docker engine.


# Before Start:
Create the credentials.json
 * Google Console -> "APIs & services -> Credentials"
 * Choose create- > "service account key" -> compute engine service account -> JSON (Download)

Build the docker image with: 
````
$ docker build -t gce_mgmt .
````
The command above will generate an alpine based image which is very small (324MB).
Alternatively you can build an ubuntu based image (678MB) with the follwing:
````
docker build -t gce_mgmt:ubuntu -f Dockerfile.ubuntu .
````
# Run 
Run the docker container, mapping the directory where the json was downloaded:

```
$ docker run --rm -v $HOME/downloads:/opt/downloads -it gce_mgmt
````

copy the json downloaded into the working directory (/gcloud) of the container (credentials.json file):
```
$ sudo cp /opt/downloads/project-123141.json credentials.json
```

load the environment variables:
````
$ source load-credentials.sh
````

If that is the first time your run this in your project, you might want to
enable the google cloud apis, otherwise press any key to ignore it.


Initialize terraform:
````
terraform init
````

Deploy the example

````
$ terraform apply
````

Access the ip address shown at the terraform output and check if nginx is running. --profit.

Clean up the deployment
````
$ terraform destroy
````


# Notes
You can access gce instances with the alias: **sshgcp instance**
There are other interesting aliases you might find useful (after generating the tfstate with terraform apply:
* ansible-ti :  ansible command plus terraform dynamic inventory
* ansible-tip : ansible-playbook command plus terraform dynamic inventory
* ansible-inventory-ti : ansible-inventory command plus terraform dynamic inventory

After deploying terraform, run ansible-tip sshscan.yml to load the ssh keys of remote nodes.

 



 



