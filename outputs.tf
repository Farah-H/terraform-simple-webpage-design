output "page_url" {
  value = "http://${aws_instance.webserver.public_ip}"
}
