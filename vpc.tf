
### VPC ###
#this will be the VPC attached to the primary first nic.
resource "google_compute_network" "public_vpc" {
  name                    = "${var.cluster_name}-vpc-${random_string.random_name_suffix.result}"
  auto_create_subnetworks = false
}
resource "google_compute_subnetwork" "public_subnet" {
  name          = "${var.cluster_name}-public-subnet-${random_string.random_name_suffix.result}"
  region        = "${var.region}"
  network       = "${google_compute_network.public_vpc.self_link}"
  ip_cidr_range = "${var.public_subnet}"
}
### Public VPC Firewall Policy ###
#Default direction is ingress
resource "google_compute_firewall" "public_firewall" {
  name    = "${var.cluster_name}-firewall-${random_string.random_name_suffix.result}"
  network = "${google_compute_network.public_vpc.name}"
  priority = "100"
    # You can add or remove  restrictions here.
    # The following would allow all UDP+TCP
    #   allow {
    #     protocol = "all"
    #   }
allow {
    protocol = "tcp"
    ports    = ["80", "443" ,"22"]
}
#Allow ping
  allow {
    protocol = "icmp"
  }
# Allowed Source Ranges, useful for restricting ssh etc.
  source_ranges = ["${var.firewall_allowed_range}"]
}
### Internal VPC ###
resource "google_compute_network" "internal_vpc" {
  name                    = "${var.cluster_name}-internal-vpc-${random_string.random_name_suffix.result}"
  auto_create_subnetworks = false
}
resource "google_compute_subnetwork" "internal_subnet" {
  name          = "${var.cluster_name}-internal-subnet-${random_string.random_name_suffix.result}"
  region        = "${var.region}"
  network       = "${google_compute_network.internal_vpc.self_link}"
  ip_cidr_range = "${var.internal_subnet}"
}
#### Internal VPC Firewall Policy ####
# Allow everything since this is internal
resource "google_compute_firewall" "internal_firewall" {
  name    = "${var.cluster_name}-internal-firewall-${random_string.random_name_suffix.result}"
  network = "${google_compute_network.internal_vpc.name}"
  priority = "100"
    # You can add or remove  restrictions here.
       allow {
         protocol = "all"
      }
# Allowed Source Ranges, useful for restricting ssh etc.
  source_ranges = ["${var.firewall_allowed_range_internal}"]
}