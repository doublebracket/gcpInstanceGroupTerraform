terraform {
  required_providers {
    google = ">=2.20.1"
  }
}
# Credentials should point to your
provider "google" {
  credentials = "${file(var.auth_key)}"
  project     = "${var.project}"
  region      = "${var.region}"
  zone        = "${var.zone}"
}

#Random 3 character string appended to the end of each name to avoid conflicts/Identify clusters
resource "random_string" "random_name_suffix" {
  length           = 3
  special          = true
  override_special = ""
  min_lower        = 3
}
resource "google_compute_instance_template" "default" {
  name        = "${var.cluster_name}-template-${random_string.random_name_suffix.result}"
  description = "This template is used to create app server instances."
  instance_description = "AutoScale Demo"
  machine_type         = "${var.instance}"
  can_ip_forward       = true

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }

  # Create a new boot disk from an image
  disk {
    source_image = "${var.autoscale_demo_image}"
    auto_delete  = true
    boot         = true
  }
  # Secondary Disk
  disk {
    auto_delete = true
    boot        = false
    disk_size_gb = 30
  }
# Public facing managment port with public IP.
  network_interface {
    subnetwork = "${google_compute_subnetwork.public_subnet.self_link}"
    # Add a public IP (default ephemeral)
    access_config {
      nat_ip = ""
    }
  }
   # Secondary Interface for internal traffic etc.
      network_interface {
     subnetwork = "${google_compute_subnetwork.internal_subnet.self_link}"
   }

  # Cloud-init user data can be specificed here
  # A linter may pick up the : as an illegal character. It should still work regardless.
  metadata = {
    startup-script = "startup-script:${file(var.cloud_init_data)}"
    ssh-keys="admin:${file(var.public_key_path)}"
  }


}
# The health check allows us to autoheal or remove and re-add instances if they become unreachable.
# This is important to consider if you change something in the image or template and instances start removing themselves
resource "google_compute_health_check" "autohealing" {
   name                = "${var.cluster_name}-healthcheck-${random_string.random_name_suffix.result}"
   check_interval_sec  = 5
   timeout_sec         = 5
   healthy_threshold   = 2
   unhealthy_threshold = 10 # 50 seconds

   tcp_health_check {
     port         = "22"
   }
 }
# The Instance group manager (AutoScale group)
resource "google_compute_region_instance_group_manager" "InstanceGroup" {
  name = "${var.cluster_name}-autoscale-manager-${random_string.random_name_suffix.result}"
  base_instance_name        = "${var.cluster_name}-instance-${random_string.random_name_suffix.result}"
  region        = "${var.region}"
  distribution_policy_zones = ["us-central1-a", "us-central1-b"]

  # To add the instances to a load balancer we set the target pool so each instance will be added on startup
  #target_pools = ["${google_compute_target_pool.AutoScaleDemoTargetPool.self_link}"]

     auto_healing_policies {
     health_check      = google_compute_health_check.autohealing.self_link
     initial_delay_sec = 300
   }
   #Rolling updates can be done through terraform.
  version {
    name = "1.0"
    instance_template         = "${google_compute_instance_template.default.self_link}"
   }

}
#### Regional AutoScaler ####
resource "google_compute_region_autoscaler" "default" {
  project  = "${var.project}"
  #Name needs to be in lowercase
  name   = "${var.cluster_name}-autoscaler-demo-${random_string.random_name_suffix.result}"
  region = "${var.region}"
  target = "${google_compute_region_instance_group_manager.InstanceGroup.self_link}"

# The min/max replicas to deploy
  autoscaling_policy {
    max_replicas    = "${var.max_replicas}"
    min_replicas    = "${var.min_replicas}"
    cooldown_period = "${var.cooldown_period}"

    cpu_utilization {
      target = "${var.cpu_utilization}"
    }
  }
}
