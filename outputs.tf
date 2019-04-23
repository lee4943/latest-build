output "app_url" {
  value = "http://${aws_lb.lb.dns_name}/builds"
}

output "health_check_url" {
  value = "http://${aws_lb.lb.dns_name}/health_check"
}

output "bastion_host_ip" {
  value = "${aws_eip.bastion_eip.public_ip}"
}

output "app_server_ip" {
  value = "${aws_instance.app.private_ip}"
}