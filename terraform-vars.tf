# How to define variables in terraform:
# https://www.terraform.io/docs/configuration/variables.html


# Name of the project, replace "teste" for your
# respective group ID
variable "GCPProjectID" {
    #this is defined into the envs.sh and 
    #only chars are allowed in these variables identifiers
    #default = "MyProject"
}

# A list of machine types is found at:
# https://cloud.google.com/compute/docs/machine-types
# prices are defined per region, before choosing an instance
# check the cost at: https://cloud.google.com/compute/pricing#machinetype
variable "GCPMachineType" {
    default = "f1-micro"
}

# Regions list is found at:
# https://cloud.google.com/compute/docs/regions-zones/regions-zones?hl=en_US
# For prices of your deployment check:
# Compute Engine dashboard -> VM instances -> Zone 
variable "GCPRegion" {
    default = "us-central1-a"
}


# placeholder for the container's user local account
variable "USR" {
    
}
