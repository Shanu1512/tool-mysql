variable "vpc_id" {
  type = string
}

variable "public_subnets" {
  type    = list(string)
  default = []
}

variable "private_subnets" {
  type    = list(string)
  default = []
}

variable "igw_id" {
  type    = string
  default = null
}

variable "nat_id" {
  type    = string
  default = null
}
