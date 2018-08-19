provider "aws" {
  region = "us-east-1"
}

# Configure the Consul provider
provider "consul" {
  address    = "${var.consul_server}:${var.consul_port}"
  datacenter = "${var.datacenter}"
}

resource "aws_instance" "app" {
  ami = "${data.consul_keys.app.var.ami}"
  instance_type = "${data.consul_keys.app.var.instance_type}"

  tags {
    Name = "${data.consul_keys.app.var.Name}"
  }
}
