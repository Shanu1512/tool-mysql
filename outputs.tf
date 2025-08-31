# VPC Outputs
output "app_vpc_id" {
  value = module.app_vpc.vpc_id
}

output "db_vpc_id" {
  value = module.db_vpc.vpc_id
}

# Subnet Outputs
output "app_subnet_id" {
  value = module.app_subnet.subnet_id
}

output "bastion_subnet_id" {
  value = module.bastion_subnet.subnet_id
}

output "db_subnet_id" {
  value = module.db_subnet.subnet_id
}

# NAT Outputs
output "app_nat_id" {
  value = module.app_nat.nat_id
}

output "db_nat_id" {
  value = module.db_nat.nat_id
}

# Route Table Outputs
output "app_private_rt_id" {
  value = module.app_route_table.private_rt_id
}

output "db_private_rt_id" {
  value = module.db_route_table.private_rt_id
}

# VPC Peering
output "vpc_peering_id" {
  value = module.vpc_peering.vpc_peering_id
}

# Security Groups
output "app_sg_id" {
  value = module.app_sg.sg_id
}

output "db_sg_id" {
  value = module.db_sg.sg_id
}

output "bastion_sg_id" {
  value = module.bastion_sg.sg_id
}

# Elastic IPs
output "app_nat_eip" {
  value = aws_eip.app_nat.public_ip
}

output "db_nat_eip" {
  value = aws_eip.db_nat.public_ip
}
