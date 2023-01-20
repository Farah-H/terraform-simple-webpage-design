output "page_url" {
  value = "http://${aws_elb.webserver.dns_name}"
}
