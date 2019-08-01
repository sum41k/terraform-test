variable "region" {   default = "eu-central-1" }
variable "access_key" {   default = "xxxxxxxxx" }
variable "secret_key" {   default = "xxxxxxxxx" }
variable "bucket" {   default = "xxxxxxxxx" }
variable "certificate_body" {   default = "certificates/self_signed.crt"}
variable "private_key" {   default = "certificates/self_signed.key"}
variable "ec2_key_name"    {   default = "xxxxxxxxx" }
variable "subnets" {
    type    = "list"
    default = ["subnet-5ed51c34", "subnet-a5f0f4d8", "subnet-51d7dc1c"]
}
variable "vpc_id"    {   default = "xxxxxxxxx" }
