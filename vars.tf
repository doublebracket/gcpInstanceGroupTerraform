
# Specify your region
variable "region" {
  type    = "string"
  default = "us-central1" #Default Region
}

variable "project" {
  type    = "string"
  default = ""
}
variable "zone"{
  type = "string"
  default = "us-central1-c"
}
variable "auth_key"{
  type = "string"
  default = "account.json"
}
# Zones to use with Instance Group
data "google_compute_zones" "get_zones" {
}
variable "autoscale_demo_image" {
  type = "string"
    #Finding out how to use marketplace images is tricky, use the following link to look them up
    # https://cloud.google.com/compute/docs/reference/rest/v1/images/getFromFamily?
  default = "projects/centos-cloud/global/images/centos-7-v20191210"
}
variable "instance" {
  type    = "string"
  default = "n1-standard-4"
}
#Must be lower-case
variable "cluster_name" {
  type    = "string"
  default = "autoscaledemo"
}
# Upload a Local ssh key to the vms
variable "public_key_path" {
  type    = "string"
  default = "~/.ssh/id_rsa.pub"
}
variable "cloud_init_data" {
  type    = "string"
  default = "./cloud_init_data"
}

#### Network Settings ####
variable "vpc_cidr" {
  type    = "string"
  default = "172.16.0.0/16"
}
variable "public_subnet" {
  type    = "string"
  default = "172.16.0.0/24"
}
variable "internal_subnet" {
  type    = "string"
  default = "172.16.8.0/24"
}

variable "firewall_allowed_range" {
  type = "string"
  default = "0.0.0.0/0"
}
variable "firewall_allowed_range_internal" {
  type = "string"
  default = "0.0.0.0/0"
}

####  AutoScaling Configuration #####
variable "max_replicas" {
  type    = number
  default = 2
}
variable "min_replicas" {
  type    = number
  default = 1
}
variable "cooldown_period" {
  type    = number
  default = 80
}
variable "cpu_utilization" {
  type    = number
  default = 0.80 #Aggregated
}
