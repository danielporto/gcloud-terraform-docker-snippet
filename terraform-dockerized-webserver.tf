
# Elemets of the cloud such as virtual servers,
# networks, firewall rules are created as resources
# syntax is: resource RESOURCE_TYPE RESOURCE_NAME
# https://www.terraform.io/docs/configuration/resources.html


# Define a frontend server at the GPC. Note that the
# resource name is used by terraform to build the dependecy DAG
# and produce the outputs. This is not the hostname.
resource "google_compute_instance" "webserver" {

    # use tags to define what firewall rules to apply and 
    # group servers by role in ansible
    tags = ["webservice"]
 
    name = "webserver" # hostname @gcp Only low case string and numbers are allowed to set the NAME
    machine_type = "${var.GCPMachineType}"
    zone = "${var.GCPRegion}"

    boot_disk {
        initialize_params {
        # image list can be found at:
        # https://cloud.google.com/compute/docs/images
        #  image = "cos-cloud/cos-stable" # google optimized container image
        image = "debian-cloud/debian-9"
        #    image = "centos-cloud/centos-7"
        }
    } #end boot_dist

    network_interface {
        network = "default"
        access_config {
        }
    } # end network_interface

} # end webserver instance


# Webserver ansible provisioner
# webserver configuration is defined via ansible playbooks
resource "ansible_host" "webserver" {
    inventory_hostname = "${google_compute_instance.webserver.network_interface.0.access_config.0.assigned_nat_ip}"
    groups = [ "webservice" ] 
    vars {
        ansible_user = "${var.USR}"
        ansible_ssh_private_key_file = "~/.ssh/google_compute_engine"
        #foo = "bar"
    }
}

# group servers by their role
resource "ansible_group" "webservice" {
    # should match the groups in ansible hosts and the TAG of compute instances
    inventory_group_name = "webservice" 
}

# print out a list of servers ips
output "webserver_addrs" {
    value = "${join(" ", google_compute_instance.webserver.*.network_interface.0.access_config.0.assigned_nat_ip)}"
}
