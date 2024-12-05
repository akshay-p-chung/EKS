variable "vpc_id" {
	description = "VPC ID"
	type        = string
}

variable "private_subnets" {
	description = "private subnets IDs"
	type        = list(string)
}

variable "cluster_name" {
	description = "EKS cluster name"
	type        = string
}

variable "kubernetes_version" {
	description = "EKS Kubernetes version"
	type        = string
}

variable "ami_type" {
	description = "EKS nodes AMI type" 
	type        = string
}

variable "instance_types" {
	description = "Node Instances" 
	type        = list(string)
}