// ==========================================
// 1. VPC & INTERNET GATEWAY
// ==========================================

// Declare VPC named "conversion-king-vpc"
resource "aws_vpc" "conversion_king_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "conversion-king-vpc"
  }
}

// Declare Internet Gateway named "conversion-king-igw"
resource "aws_internet_gateway" "conversion_king_igw" {
  vpc_id = aws_vpc.conversion_king_vpc.id

  tags = {
    Name = "conversion-king-igw"
  }
}

// ==========================================
// 2. SUBNETS (PUBLIC, PRIVATE APP, PRIVATE DATA)
// ==========================================

// Declare Public Subnet 1 (us-east-1a)
resource "aws_subnet" "conversion_king_public_subnet" {
  vpc_id                  = aws_vpc.conversion_king_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "conversion-king-public-subnet-1"
  }
}

// Declare Public Subnet 2 (us-east-1b)
resource "aws_subnet" "conversion_king_public_subnet_2" {
  vpc_id                  = aws_vpc.conversion_king_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}b"

  tags = {
    Name = "conversion-king-public-subnet-2"
  }
}

// Declare Private Application Subnet 1 (us-east-1a)
resource "aws_subnet" "conversion_king_private_subnet" {
  vpc_id                  = aws_vpc.conversion_king_vpc.id
  cidr_block              = "10.0.10.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "conversion-king-private-app-subnet-1"
  }
}

// Declare Private Application Subnet 2 (us-east-1b)
resource "aws_subnet" "conversion_king_private_subnet_2" {
  vpc_id                  = aws_vpc.conversion_king_vpc.id
  cidr_block              = "10.0.11.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_region}b"

  tags = {
    Name = "conversion-king-private-app-subnet-2"
  }
}

// Declare Private Data Subnet 1 (us-east-1a)
resource "aws_subnet" "conversion_king_private_data_subnet_1" {
  vpc_id                  = aws_vpc.conversion_king_vpc.id
  cidr_block              = "10.0.20.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_region}a"

  tags = {
    Name = "conversion-king-private-data-subnet-1"
  }
}

// Declare Private Data Subnet 2 (us-east-1b)
resource "aws_subnet" "conversion_king_private_data_subnet_2" {
  vpc_id                  = aws_vpc.conversion_king_vpc.id
  cidr_block              = "10.0.21.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "${var.aws_region}b"

  tags = {
    Name = "conversion-king-private-data-subnet-2"
  }
}

// ==========================================
// 3. EIP & NAT GATEWAY
// ==========================================

// Declare Elastic IP for NAT Gateway
resource "aws_eip" "conversion_king_nat_eip" {
  domain = "vpc"

  tags = {
    Name = "conversion-king-nat-eip"
  }
}

// Declare NAT Gateway in Public Subnet 1
resource "aws_nat_gateway" "conversion_king_nat_gw" {
  allocation_id = aws_eip.conversion_king_nat_eip.id
  subnet_id     = aws_subnet.conversion_king_public_subnet.id

  tags = {
    Name = "conversion-king-nat-gateway"
  }
}

// ==========================================
// 4. ROUTE TABLES & ROUTE TABLE ASSOCIATIONS
// ==========================================

// Declare Public Route Table
resource "aws_route_table" "conversion_king_public_rt" {
  vpc_id = aws_vpc.conversion_king_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.conversion_king_igw.id
  }

  tags = {
    Name = "conversion-king-public-rt"
  }
}

// Associate Public Subnets with Public Route Table
resource "aws_route_table_association" "conversion_king_public_rt_assoc" {
  subnet_id      = aws_subnet.conversion_king_public_subnet.id
  route_table_id = aws_route_table.conversion_king_public_rt.id
}

resource "aws_route_table_association" "conversion_king_public_rt_assoc_2" {
  subnet_id      = aws_subnet.conversion_king_public_subnet_2.id
  route_table_id = aws_route_table.conversion_king_public_rt.id
}

// Declare Private Route Table (using NAT Gateway for outbound egress)
resource "aws_route_table" "conversion_king_private_rt" {
  vpc_id = aws_vpc.conversion_king_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.conversion_king_nat_gw.id
  }

  tags = {
    Name = "conversion-king-private-rt"
  }
}

// Associate Private Application Subnets with Private Route Table
resource "aws_route_table_association" "conversion_king_private_rt_assoc_1" {
  subnet_id      = aws_subnet.conversion_king_private_subnet.id
  route_table_id = aws_route_table.conversion_king_private_rt.id
}

resource "aws_route_table_association" "conversion_king_private_rt_assoc_2" {
  subnet_id      = aws_subnet.conversion_king_private_subnet_2.id
  route_table_id = aws_route_table.conversion_king_private_rt.id
}

// Associate Private Data Subnets with Private Route Table
resource "aws_route_table_association" "conversion_king_private_data_rt_assoc_1" {
  subnet_id      = aws_subnet.conversion_king_private_data_subnet_1.id
  route_table_id = aws_route_table.conversion_king_private_rt.id
}

resource "aws_route_table_association" "conversion_king_private_data_rt_assoc_2" {
  subnet_id      = aws_subnet.conversion_king_private_data_subnet_2.id
  route_table_id = aws_route_table.conversion_king_private_rt.id
}



