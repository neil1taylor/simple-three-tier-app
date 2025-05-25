# main.tf - Resource definitions

# IBM Cloud Provider Configuration
terraform {
  required_providers {
    ibm = {
      source  = "IBM-Cloud/ibm"
      version = "~> 1.78.0"
    }
  }
}

provider "ibm" {
  region = var.region
}

locals {
  prefix = "team-${var.team_number}"
  mgmt_subnet_cidr = "10.${var.team_number}.1.0/24"
  vpc_address_prefix = "10.${var.team_number}.4.0/24"
  web_subnet_cidr = "10.${var.team_number}.4.0/26"
  app_subnet_cidr = "10.${var.team_number}.4.64/26"
  db_subnet_cidr = "10.${var.team_number}.4.128/26"
  web_rip_address = "10.${var.team_number}.4.4"
  app_rip_address = "10.${var.team_number}.4.68"
  db_rip_address  = "10.${var.team_number}.4.132"
  web_subnet_default_gw = "10.${var.team_number}.4.1"
  app_subnet_default_gw = "10.${var.team_number}.4.65"
  db_subnet_default_gw = "10.${var.team_number}.4.129"
}

# Create Resource Group
resource "ibm_resource_group" "app1_rg" {
  name = "${local.prefix}-${var.resource_group_name}"
}

# Create VPC
resource "ibm_is_vpc" "app1_vpc" {
  name                        = "${local.prefix}-${var.vpc_name}"
  resource_group              = ibm_resource_group.app1_rg.id
  address_prefix_management   = "manual"
  default_network_acl_name    = "${local.prefix}-default-acl"
  default_security_group_name = "${local.prefix}-default-rt"
}

# Create the VPC address prefix
resource "ibm_is_vpc_address_prefix" "example" {
  name = "example-address-prefix"
  zone = var.zone
  vpc  = ibm_is_vpc.app1_vpc.id
  cidr = local.vpc_address_prefix
}

# Create Public Gateway
resource "ibm_is_public_gateway" "pgw_02_pgw" {
  name           = "${local.prefix}-${var.public_gateway_name}"
  vpc            = ibm_is_vpc.app1_vpc.id
  resource_group = ibm_resource_group.app1_rg.id
  zone           = var.zone
}

# Create Security Groups
resource "ibm_is_security_group" "app1_lb_sg" {
  name           = "${local.prefix}-${var.lb_sg_name}"
  vpc            = ibm_is_vpc.app1_vpc.id
  resource_group = ibm_resource_group.app1_rg.id
}

resource "ibm_is_security_group" "app1_web_sg" {
  name           = "${local.prefix}-${var.web_sg_name}"
  vpc            = ibm_is_vpc.app1_vpc.id
  resource_group = ibm_resource_group.app1_rg.id
}

resource "ibm_is_security_group" "app1_app_sg" {
  name           = "${local.prefix}-${var.app_sg_name}"
  vpc            = ibm_is_vpc.app1_vpc.id
  resource_group = ibm_resource_group.app1_rg.id
}

resource "ibm_is_security_group" "app1_db_sg" {
  name           = "${local.prefix}-${var.db_sg_name}"
  vpc            = ibm_is_vpc.app1_vpc.id
  resource_group = ibm_resource_group.app1_rg.id
}

# Add security group rules
# Load balancer server security group rules
resource "ibm_is_security_group_rule" "lb_sg_inbound_http" {
  group     = ibm_is_security_group.app1_lb_sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  local     = local.web_subnet_cidr
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "lb_sg_outbound" {
  group     = ibm_is_security_group.app1_lb_sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  local     = "0.0.0.0/0"
}


# Web server security group rules
resource "ibm_is_security_group_rule" "web_sg_inbound_http" {
  group     = ibm_is_security_group.app1_web_sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  local     = local.web_subnet_cidr
  tcp {
    port_min = 80
    port_max = 80
  }
}

resource "ibm_is_security_group_rule" "web_sg_inbound_https" {
  group     = ibm_is_security_group.app1_web_sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  local     = local.web_subnet_cidr
  tcp {
    port_min = 443
    port_max = 443
  }
}

resource "ibm_is_security_group_rule" "web_sg_inbound_ssh" {
  group     = ibm_is_security_group.app1_web_sg.id
  direction = "inbound"
  remote    = local.mgmt_subnet_cidr
  local     = local.web_subnet_cidr
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "web_sg_outbound" {
  group     = ibm_is_security_group.app1_web_sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  local     = "0.0.0.0/0"
}

# App server security group rules
resource "ibm_is_security_group_rule" "app_sg_inbound_app" {
  group     = ibm_is_security_group.app1_app_sg.id
  direction = "inbound"
  remote    = ibm_is_subnet_reserved_ip.web_01_rip.address
  local     = local.app_subnet_cidr
  tcp {
    port_min = var.app_port
    port_max = var.app_port
  }
}

resource "ibm_is_security_group_rule" "app_sg_inbound_ssh" {
  group     = ibm_is_security_group.app1_app_sg.id
  direction = "inbound"
  remote    = local.mgmt_subnet_cidr
  local     = local.app_subnet_cidr
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "app_sg_outbound" {
  group     = ibm_is_security_group.app1_app_sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  local     = "0.0.0.0/0"
}

# DB server security group rules
resource "ibm_is_security_group_rule" "db_sg_inbound_db" {
  group     = ibm_is_security_group.app1_db_sg.id
  direction = "inbound"
  remote    = ibm_is_subnet_reserved_ip.app_01_rip.address
  local     = local.db_subnet_cidr
  tcp {
    port_min = var.db_port
    port_max = var.db_port
  }
}

resource "ibm_is_security_group_rule" "db_sg_inbound_ssh" {
  group     = ibm_is_security_group.app1_db_sg.id
  direction = "inbound"
  remote    = local.mgmt_subnet_cidr
  local     = local.db_subnet_cidr
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "db_sg_outbound" {
  group     = ibm_is_security_group.app1_db_sg.id
  direction = "outbound"
  remote    = "0.0.0.0/0"
  local     = "0.0.0.0/0"
}

# Create Network ACL
resource "ibm_is_network_acl" "app1_acl" {
  name           = "${local.prefix}-${var.acl_name}"
  vpc            = ibm_is_vpc.app1_vpc.id
  resource_group = ibm_resource_group.app1_rg.id
  
  # Allow all outbound traffic
  rules {
    name        = "allow-all-outbound"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "outbound"
  }
  
  # Allow all inbound traffic
  rules {
    name        = "allow-all-inbound"
    action      = "allow"
    source      = "0.0.0.0/0"
    destination = "0.0.0.0/0"
    direction   = "inbound"
  }
}

# Create Web Subnet
resource "ibm_is_subnet" "app1_web_sn" {
  name            = "${local.prefix}-${var.web_subnet_name}"
  vpc             = ibm_is_vpc.app1_vpc.id
  zone            = var.zone
  ipv4_cidr_block = local.web_subnet_cidr
  network_acl     = ibm_is_network_acl.app1_acl.id
  public_gateway  = ibm_is_public_gateway.pgw_02_pgw.id
  resource_group  = ibm_resource_group.app1_rg.id
}

# Create App Subnet
resource "ibm_is_subnet" "app1_app_sn" {
  name            = "${local.prefix}-${var.app_subnet_name}"
  vpc             = ibm_is_vpc.app1_vpc.id
  zone            = var.zone
  ipv4_cidr_block = local.app_subnet_cidr
  network_acl     = ibm_is_network_acl.app1_acl.id
  public_gateway  = ibm_is_public_gateway.pgw_02_pgw.id
  resource_group  = ibm_resource_group.app1_rg.id
}

# Create DB Subnet
resource "ibm_is_subnet" "app1_db_sn" {
  name            = "${local.prefix}-${var.db_subnet_name}"
  vpc             = ibm_is_vpc.app1_vpc.id
  zone            = var.zone
  ipv4_cidr_block = local.db_subnet_cidr
  network_acl     = ibm_is_network_acl.app1_acl.id
  public_gateway  = ibm_is_public_gateway.pgw_02_pgw.id
}

# Custom Route Tables
resource "ibm_is_vpc_routing_table" "app_route_table" {
  vpc                           = ibm_is_vpc.app1_vpc.id
  name                          = "${local.prefix}-app1-app-routes"
  route_direct_link_ingress     = false
  route_internet_ingress        = false
  route_transit_gateway_ingress = false
  route_vpc_zone_ingress        = false
  tags                          = ["terraform", "demo", "app-tier"]
}

resource "ibm_is_vpc_routing_table" "db_route_table" {
  vpc                           = ibm_is_vpc.app1_vpc.id
  name                          = "${local.prefix}-app1-db-routes"
  route_direct_link_ingress     = false
  route_internet_ingress        = false
  route_transit_gateway_ingress = false
  route_vpc_zone_ingress        = false
  tags                          = ["terraform", "demo", "db-tier"]
}

# Custom Routes
# Allow app subnet to communicate with database subnet
resource "ibm_is_vpc_routing_table_route" "app_to_db_route" {
  vpc           = ibm_is_vpc.app1_vpc.id
  routing_table = ibm_is_vpc_routing_table.app_route_table.routing_table
  destination   = local.db_subnet_cidr
  action        = "deliver"
  name          = "allow-app-to-db"
  zone          = var.zone
  next_hop      = local.app_subnet_default_gw  # Gateway IP of app subnet
}

# Allow database subnet to respond to app subnet
resource "ibm_is_vpc_routing_table_route" "db_to_app_route" {
  vpc           = ibm_is_vpc.app1_vpc.id
  routing_table = ibm_is_vpc_routing_table.db_route_table.routing_table
  destination   = local.app_subnet_cidr
  action        = "deliver"
  name          = "allow-db-to-app"
  zone          = var.zone
  next_hop      = local.db_subnet_default_gw   # Gateway IP of db subnet
}

# Block internet access from database subnet
resource "ibm_is_vpc_routing_table_route" "db_block_internet" {
  vpc           = ibm_is_vpc.app1_vpc.id
  routing_table = ibm_is_vpc_routing_table.db_route_table.routing_table
  destination   = "0.0.0.0/0"
  action        = "drop"
  name          = "block-internet-access"
  zone          = var.zone
  next_hop      = ""
}

# Allow app subnet to access web subnet
resource "ibm_is_vpc_routing_table_route" "app_to_web_route" {
  vpc           = ibm_is_vpc.app1_vpc.id
  routing_table = ibm_is_vpc_routing_table.app_route_table.routing_table
  destination   = local.web_subnet_cidr
  action        = "deliver"
  name          = "allow-app-to-web"
  zone          = var.zone
  next_hop      = local.app_subnet_default_gw  # Gateway IP of app subnet
}

# Route table associations
resource "ibm_is_subnet_routing_table_attachment" "app_subnet_routing" {
  subnet        = ibm_is_subnet.app1_app_sn.id
  routing_table = ibm_is_vpc_routing_table.app_route_table.routing_table
}

resource "ibm_is_subnet_routing_table_attachment" "db_subnet_routing" {
  subnet        = ibm_is_subnet.app1_db_sn.id
  routing_table = ibm_is_vpc_routing_table.db_route_table.routing_table
}

# Create Reserved IPs
resource "ibm_is_subnet_reserved_ip" "web_01_rip" {
  subnet  = ibm_is_subnet.app1_web_sn.id
  name    = "${local.prefix}-${var.web_rip_name}"
  address = local.web_rip_address
}

resource "ibm_is_subnet_reserved_ip" "app_01_rip" {
  subnet  = ibm_is_subnet.app1_app_sn.id
  name    = "${local.prefix}-${var.app_rip_name}"
  address = local.app_rip_address
}

resource "ibm_is_subnet_reserved_ip" "db_01_rip" {
  subnet  = ibm_is_subnet.app1_db_sn.id
  name    = "${local.prefix}-${var.db_rip_name}"
  address = local.db_rip_address
}

# Create Virtual Network Interfaces
resource "ibm_is_virtual_network_interface" "web_01_vni" {
  name            = "${local.prefix}-${var.web_vni_name}"
  subnet          = ibm_is_subnet.app1_web_sn.id
  security_groups = [ibm_is_security_group.app1_web_sg.id]
  primary_ip {
    reserved_ip = ibm_is_subnet_reserved_ip.web_01_rip.id
  }
}

resource "ibm_is_virtual_network_interface" "app_01_vni" {
  name            = "${local.prefix}-${var.app_vni_name}"
  subnet          = ibm_is_subnet.app1_app_sn.id
  security_groups = [ibm_is_security_group.app1_app_sg.id]
  primary_ip {
    reserved_ip = ibm_is_subnet_reserved_ip.app_01_rip.id
  }
}

resource "ibm_is_virtual_network_interface" "db_01_vni" {
  name            = "${local.prefix}-${var.db_vni_name}"
  subnet          = ibm_is_subnet.app1_db_sn.id
  security_groups = [ibm_is_security_group.app1_db_sg.id]
  primary_ip {
    reserved_ip = ibm_is_subnet_reserved_ip.db_01_rip.id
  }
}

# Look up the image
data "ibm_is_image" "ubuntu" {
  name = var.image_name
}

# Get SSH Key
data "ibm_is_ssh_key" "ssh_key" {
  name = "${local.prefix}-${var.ssh_key_name}"
}

# Create Virtual Server Instances
resource "ibm_is_instance" "web_01_vsi" {
  name           = "${local.prefix}-${var.web_vsi_name}"
  image          = data.ibm_is_image.ubuntu.id
  profile        = var.instance_profile
  vpc            = ibm_is_vpc.app1_vpc.id
  zone           = var.zone
  keys           = [data.ibm_is_ssh_key.ssh_key.id]
  resource_group = ibm_resource_group.app1_rg.id
  user_data      = file(var.web_user_data_file)
  boot_volume {
    name = "${local.prefix}-${var.web_vsi_name}-boot-vol"
  }
  primary_network_attachment {
    name = "web-01-vsi"
    virtual_network_interface { 
      id = ibm_is_virtual_network_interface.web_01_vni.id
    }
  }
}

resource "ibm_is_instance" "app_01_vsi" {
  name           = "${local.prefix}-${var.app_vsi_name}"
  image          = data.ibm_is_image.ubuntu.id
  profile        = var.instance_profile
  vpc            = ibm_is_vpc.app1_vpc.id
  zone           = var.zone
  keys           = [data.ibm_is_ssh_key.ssh_key.id]
  resource_group = ibm_resource_group.app1_rg.id
  user_data      = file(var.app_user_data_file)
   boot_volume {
    name = "${local.prefix}-${var.app_vsi_name}-boot-vol"
  }
  primary_network_attachment {
    name = "app-01-vsi"
    virtual_network_interface { 
      id = ibm_is_virtual_network_interface.app_01_vni.id
    }
  }
}

resource "ibm_is_instance" "db_01_vsi" {
  name           = "${local.prefix}-${var.db_vsi_name}"
  image          = data.ibm_is_image.ubuntu.id
  profile        = var.instance_profile
  vpc            = ibm_is_vpc.app1_vpc.id
  zone           = var.zone
  keys           = [data.ibm_is_ssh_key.ssh_key.id]
  resource_group = ibm_resource_group.app1_rg.id
  user_data      = file(var.db_user_data_file)
   boot_volume {
    name = "${local.prefix}-${var.db_vsi_name}-boot-vol"
  }
  primary_network_attachment {
    name = "db-01-vsi"
    virtual_network_interface { 
      id = ibm_is_virtual_network_interface.db_01_vni.id
    }
  }
}

# Create load-balancer
resource "ibm_is_lb" "app1_lb" {
  name            = "${local.prefix}-app1-lb"
  subnets         = [ibm_is_subnet.app1_web_sn.id, ibm_is_subnet.app1_web_sn.id]
  resource_group  = ibm_resource_group.app1_rg.id
  security_groups = [ibm_is_security_group.app1_lb_sg.id]
}

# Add load-balancer pool
resource "ibm_is_lb_pool" "app1_lb_pool" {
  name           = "${local.prefix}-app1-lb-pool"
  lb             = ibm_is_lb.app1_lb.id
  algorithm      = "round_robin"
  protocol       = "http"
  health_delay   = 60
  health_retries = 5
  health_timeout = 30
  health_type    = "http"
  proxy_protocol = "v1"
}

# Add a pool member to the pool
resource "ibm_is_lb_pool_member" "app1_lb_pool_member" {
  lb        = ibm_is_lb.app1_lb.id
  pool      = element(split("/", ibm_is_lb_pool.app1_lb_pool.id), 1)
  port      = 80
  target_id = ibm_is_instance.web_01_vsi.id
  weight    = 60
}

# Add a listener
resource "ibm_is_lb_listener" "app1_lb_lsnr" {
  lb       = ibm_is_lb.app1_lb.id
  port     = "80"
  protocol = "http"
}

# Output information
output "vpc_id" {
  value = ibm_is_vpc.app1_vpc.id
}

output "web_server_ip" {
  value = ibm_is_subnet_reserved_ip.web_01_rip.address
}

output "app_server_ip" {
  value = ibm_is_subnet_reserved_ip.app_01_rip.address
}

output "db_server_ip" {
  value = ibm_is_subnet_reserved_ip.db_01_rip.address
}

output "lb_fqdn" {
  value = ibm_is_lb.app1_lb.hostname
}