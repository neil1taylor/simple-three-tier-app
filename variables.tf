# variables.tf - Variable definitions

variable "region" {
  description = "IBM Cloud region where resources will be deployed"
  type        = string
  default     = "us-south"
}

variable "zone" {
  description = "Availability zone where resources will be deployed"
  type        = string
  default     = "us-south-1"
}

# Prefix
variable "team_number" {
  description = "The number of your team e.g. 1 for 'Team 1'"
  type        = number
  default     = 1
}

# Resource group
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "app1-rg"
}

# VPC
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "app1-vpc"
}

# Public Gateway
variable "public_gateway_name" {
  description = "Name of the public gateway"
  type        = string
  default     = "pgw-02-pgw"
}

# Security Groups
variable "lb_sg_name" {
  description = "Name of the load balancer security group"
  type        = string
  default     = "app1-lb-sg"
}

variable "web_sg_name" {
  description = "Name of the web tier security group"
  type        = string
  default     = "app1-web-sg"
}

variable "app_sg_name" {
  description = "Name of the application tier security group"
  type        = string
  default     = "app1-app-sg"
}

variable "db_sg_name" {
  description = "Name of the database tier security group"
  type        = string
  default     = "app1-db-sg"
}

# Port configurations
variable "app_port" {
  description = "Port for the application server"
  type        = number
  default     = 3000
}

variable "db_port" {
  description = "Port for the database server"
  type        = number
  default     = 5432
}

# ACL
variable "acl_name" {
  description = "Name of the network ACL"
  type        = string
  default     = "app1-acl"
}

# Subnets
variable "web_subnet_name" {
  description = "Name of the Web subnet"
  type        = string
  default     = "app1-web-sn"
}

variable "app_subnet_name" {
  description = "Name of the Application subnet"
  type        = string
  default     = "app1-app-sn"
}

variable "db_subnet_name" {
  description = "Name of the Database subnet"
  type        = string
  default     = "app1-db-sn"
}

# Reserved IPs
variable "web_rip_name" {
  description = "Name of the web server reserved IP"
  type        = string
  default     = "web-01-rip"
}

variable "app_rip_name" {
  description = "Name of the application server reserved IP"
  type        = string
  default     = "app-01-rip"
}

variable "db_rip_name" {
  description = "Name of the database server reserved IP"
  type        = string
  default     = "db-01-rip"
}

# Virtual Network Interfaces
variable "web_vni_name" {
  description = "Name of the web server network interface"
  type        = string
  default     = "web-01-vni"
}

variable "app_vni_name" {
  description = "Name of the application server network interface"
  type        = string
  default     = "app-01-vni"
}

variable "db_vni_name" {
  description = "Name of the database server network interface"
  type        = string
  default     = "db-01-vni"
}

# Image and Instance configuration
variable "image_name" {
  description = "Name of the OS image to use for instances"
  type        = string
  default     = "ibm-ubuntu-20-04-minimal-amd64-2"
}

variable "ssh_key_name" {
  description = "Name of the SSH key to use for the VSI instances"
  type        = string
  default     = "ssh-key-1"
}

variable "instance_profile" {
  description = "Profile type for the virtual server instances"
  type        = string
  default     = "cx2-2x4"
}

# User data files
variable "web_user_data_file" {
  description = "Path to the user data script for the web server"
  type        = string
  default     = "userdata/web_user_data.sh"
}

variable "app_user_data_file" {
  description = "Path to the user data script for the application server"
  type        = string
  default     = "userdata/app_user_data.sh"
}

variable "db_user_data_file" {
  description = "Path to the user data script for the database server"
  type        = string
  default     = "userdata/db_user_data.sh"
}

# VSI names
variable "web_vsi_name" {
  description = "Name of the web server virtual server instance"
  type        = string
  default     = "web-01-vsi"
}

variable "app_vsi_name" {
  description = "Name of the application server virtual server instance"
  type        = string
  default     = "app-01-vsi"
}

variable "db_vsi_name" {
  description = "Name of the database server virtual server instance"
  type        = string
  default     = "db-01-vsi"
}