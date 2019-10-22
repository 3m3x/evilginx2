variable "aws_profile" {
  description = "Name of AWS CLI profile used to create resources under"
}
variable "ssh_pub_key" {
  description = "An SSH public key used to access the EC2 instance running evilginx"
}
variable "package_url" {
  description = "URL of evilginx release package to download and install"
}
