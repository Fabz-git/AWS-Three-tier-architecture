

variable "region" {
description = "region for VPC launch"  
}


variable "vpc_cidr" {
description = "cidr block for myvpc"
}


variable "public_subnet_1_cidr" {
description = "cidr block for my first public subnet"
}

variable "public_subnet_2_cidr" {
description = "cidr block for my second public subnet"
}

variable "private_subnet_1_cidr" {
description = "cidr block for my first private subnet"
}

variable "private_subnet_2_cidr" {
description = "cidr block for my second private subnet"
}

variable "private_subnet_3_cidr" {
    description = "cidr block for my third private subnet"
}

variable "private_subnet_4_cidr" {
    description = "cidr block for my fourth private subnet"
}




variable "instance_type" {
description = "instance type for the ec2 instnace"
}

variable "image_id" {
    description = "The ID of the AMI"
  type        = string
}


