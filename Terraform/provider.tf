terraform {
	backend "s3" {}
	required_providers {
		aws = {
			source = "hashicorp/aws"
			version = ">= 3.68.0"
		}
		helm = {
			source = "hashicorp/helm"
			version = "2.13.0"
		}
	}
}

#Configure the AWS Provider
provider "aws" {
	region = "us-east-1"
}

#Helm provider for installing Loadbalancer controller.
provider "helm" {
	kubernetes {
		host = module.eks.cluster_endpoint
		cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
		exec {
			api_version = "client.authentication.k8s.io/v1betal"
			args = ["eks", "get-token", "--profile", "labs", "--cluster-name", module.eks.cluster_name]
			command = "aws"
		}
	}
}