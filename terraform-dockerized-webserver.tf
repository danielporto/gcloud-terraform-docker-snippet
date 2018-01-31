
# Elemets of the cloud such as virtual servers,
# networks, firewall rules are created as resources
# syntax is: resource RESOURCE_TYPE RESOURCE_NAME
# https://www.terraform.io/docs/configuration/resources.html

# create the frontend server (note that output depends on this identifier)
resource "google_compute_instance" "dockerized_webserver" {
    tags = ["webservice"]
    count = 1
    # only low case string and numbers are allowed to set the NAME
    name = "dockerweb${count.index + 1}"
    machine_type = "${var.GCPMachineType}"
    zone = "${var.GCPRegion}"

    boot_disk {
        initialize_params {
        # image list can be found at:
        # https://cloud.google.com/compute/docs/images
        image = "cos-cloud/cos-stable"
        }
    }

    network_interface {
        network = "default"
        access_config {
        }
    }

    provisioner "remote-exec" {
        connection {
            type    = "ssh"
            user    = "${var.USR}"
            private_key = "${file("~/.ssh/google_compute_engine")}"
            timeout = "120s"
    }

        inline = [
            "docker run --rm --name tmp-nginx-container -d -p 80:80 nginx:alpine",
        ]
    }

}

output "dockerWeb_ip" {
    value = "${join(" ", google_compute_instance.dockerized_webserver.*.network_interface.0.access_config.0.assigned_nat_ip)}"
}

