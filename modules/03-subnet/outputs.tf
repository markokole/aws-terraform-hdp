#output "vpc_id" {
#  value = "${aws_subnet.terraform_subnet.vpc_id}"
#}

output "route_id" {
  value = "${aws_route.route.id}"
}

#output "cidr_block" {
#  value = "${aws_subnet.terraform_subnet.cidr_block}"
#}
