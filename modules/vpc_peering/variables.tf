variable "requester_vpc_id" {
  type = string
}

variable "accepter_vpc_id" {
  type = string
}

variable "peer_region" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "name" {
  type = string
}
