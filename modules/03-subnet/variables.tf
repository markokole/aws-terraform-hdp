variable "path_in_consul" {
  default   = "test/master/aws/test-instance"
}
variable "consul_server" {
  default   = "127.0.0.1"
}
variable "consul_port" {
  default   = "8500"
}
variable "datacenter" {
  default   = "dc1"
}

data "consul_keys" "app" {
  key {
    name    = "region"
    path    = "${var.path_in_consul}/region"
  }
  key {
    name    = "vpc_id"
    path    = "${var.path_in_consul}/vpc_id"
  }
  key {
    name    = "cidr_block"
    path    = "${var.path_in_consul}/cidr_block"
  }
  key {
    name    = "availability_zone"
    path    = "${var.path_in_consul}/availability_zone"
  }
  key {
    name    = "main_route_table_id"
    path    = "${var.path_in_consul}/main_route_table_id"
  }
  key {
    name    = "igw_id"
    path    = "${var.path_in_consul}/igw_id"
  }
}
