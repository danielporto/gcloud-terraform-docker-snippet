# Elemets of the cloud such as virtual servers,
# networks, firewall rules are created as resources
# syntax is: resource RESOURCE_TYPE RESOURCE_NAME
# https://www.terraform.io/docs/configuration/resources.html

resource "google_compute_firewall" "firewall" {
  name    = "frontend-fw"
  network = "default"

  allow {
    protocol = "tcp"
    ports = ["80", "443", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["webservice", "lbalancer"]
}