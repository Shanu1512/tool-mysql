# -------------------------------
# VPC Modules
# -------------------------------
module "app_vpc" {
  source     = "./modules/vpc"
  cidr_block = var.app_vpc_cidr
  vpc_name   = "app-vpc"
}

module "db_vpc" {
  source     = "./modules/vpc"
  cidr_block = var.db_vpc_cidr
  vpc_name   = "db-vpc"
}

# -------------------------------
# Subnet Modules
# -------------------------------
module "app_subnet" {
  source     = "./modules/subnet"
  vpc_id     = module.app_vpc.vpc_id
  cidr_block = var.app_subnet_cidr
  az         = var.az
  name       = "app-subnet"
}

module "bastion_subnet" {
  source     = "./modules/subnet"
  vpc_id     = module.app_vpc.vpc_id
  cidr_block = var.bastion_subnet_cidr
  az         = var.az
  name       = "bastion-subnet"
}

module "db_subnet" {
  source     = "./modules/subnet"
  vpc_id     = module.db_vpc.vpc_id
  cidr_block = var.db_subnet_cidr
  az         = var.az
  name       = "db-subnet"
}

# -------------------------------
# IGW Modules
# -------------------------------
module "app_igw" {
  source = "./modules/igw"
  vpc_id = module.app_vpc.vpc_id
  name   = "app-igw"
}

module "db_igw" {
  source = "./modules/igw"
  vpc_id = module.db_vpc.vpc_id
  name   = "db-igw"
}

# -------------------------------
# NAT Gateways
# -------------------------------
module "app_nat" {
  source    = "./modules/nat"
  subnet_id = module.bastion_subnet.subnet_id
  eip_id    = aws_eip.app_nat.id
}

# for db nat
module "db_nat" {
  source    = "./modules/nat"
  subnet_id = module.db_subnet.subnet_id
  eip_id    = aws_eip.db_nat.id
}

# -------------------------------
# Route Tables
# -------------------------------
module "app_route_table" {
  source          = "./modules/route_table"
  vpc_id          = module.app_vpc.vpc_id
  public_subnets  = []
  private_subnets = [module.app_subnet.subnet_id]
  igw_id          = module.app_igw.igw_id
  nat_id          = module.app_nat.nat_id
}


module "db_route_table" {
  source          = "./modules/route_table"
  vpc_id          = module.db_vpc.vpc_id
  public_subnets  = []
  private_subnets = [module.db_subnet.subnet_id]
  igw_id          = module.db_igw.igw_id
  nat_id          = module.db_nat.nat_id
}

# -------------------------------
# VPC Peering
# -------------------------------
module "vpc_peering" {
  source           = "./modules/vpc_peering"
  requester_vpc_id = module.app_vpc.vpc_id
  accepter_vpc_id  = module.db_vpc.vpc_id
  name             = "app-db-peering"
}

# -------------------------------
# Routes using Peering
# -------------------------------
resource "aws_route" "app_to_db" {
  route_table_id            = module.app_route_table.private_rt_id
  destination_cidr_block    = var.db_vpc_cidr
  vpc_peering_connection_id = module.vpc_peering.vpc_peering_id
}

resource "aws_route" "db_to_app" {
  route_table_id            = module.db_route_table.private_rt_id
  destination_cidr_block    = var.app_vpc_cidr
  vpc_peering_connection_id = module.vpc_peering.vpc_peering_id
}

# Elastic IP for App NAT
resource "aws_eip" "app_nat" {
  domain = "vpc"
}

# Elastic IP for DB NAT
resource "aws_eip" "db_nat" {
  domain = "vpc"
}

module "app_sg" {
  source      = "./modules/security_group"
  name        = "app-sg"
  description = "App server security group"
  vpc_id      = module.app_vpc.vpc_id

  ingress_rules = [
    {
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      security_groups = [module.db_sg.sg_id] # DB SG reference
      description     = "MySQL access to DB"
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP access"
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS access"
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = { Name = "app-sg" }
}

module "db_sg" {
  source      = "./modules/security_group"
  name        = "db-sg"
  description = "Database security group"
  vpc_id      = module.db_vpc.vpc_id

  ingress_rules = [
    {
      from_port       = 3306
      to_port         = 3306
      protocol        = "tcp"
      security_groups = [module.app_sg.sg_id]
      description     = "Allow MySQL from App"
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = { Name = "db-sg" }
}


# Bastion SG can remain as generic
module "bastion_sg" {
  source      = "./modules/security_group"
  name        = "bastion-sg"
  description = "Bastion host security group"
  vpc_id      = module.app_vpc.vpc_id

  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH from my IP"
    }
  ]

  egress_rules = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all outbound"
    }
  ]
}

# -------------------------------
# Bastion EC2
# -------------------------------
module "bastion_ec2" {
  source             = "./modules/ec2"
  name               = "bastion"
  ami_id             = var.ami_id
  instance_type      = var.bastion_instance_type
  subnet_id          = module.bastion_subnet.subnet_id
  key_name           = var.key_name
  security_group_ids = [module.bastion_sg.sg_id]
  associate_public_ip = true
}

# -------------------------------
# App EC2
# -------------------------------
module "app_ec2" {
  source             = "./modules/ec2"
  name               = "app"
  ami_id             = var.ami_id
  instance_type      = var.app_instance_type
  subnet_id          = module.app_subnet.subnet_id
  key_name           = var.key_name
  security_group_ids = [module.app_sg.sg_id]
  associate_public_ip = false
}

# -------------------------------
# DB EC2 (optional, private)
# -------------------------------
module "db_ec2" {
  source             = "./modules/ec2"
  name               = "db"
  ami_id             = var.ami_id
  instance_type      = var.db_instance_type
  subnet_id          = module.db_subnet.subnet_id
  key_name           = var.key_name
  security_group_ids = [module.db_sg.sg_id]
  associate_public_ip = false
}
