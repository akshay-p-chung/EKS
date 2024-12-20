#EKS

module "eks" {
	source = "terraform-aws-modules/eks/aws"

	cluster_name    = var.cluster_name
	cluster_version = var.kubernetes_version

	iam_role_additional_policies = {
		ElasticLoadBalancingFullAccess = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
	}
	
	vpc_id = var.vpc_id
	subnet_ids = var.private_subnets

	enable_irsa = true
	cluster_endpoint_public_access = true

  cluster_security_group_additional_rules = {
    https-ingress = {
      cidr_blocks = ["0.0.0.0/0"]
      description = "Allow all traffic from remote node/pod network"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      type        = "ingress"
    }
  }

	eks_managed_node_group_defaults = {
		ami_type       = var.ami_type
		instance_types = var.instance_types
		create_node_security_group = false
		iam_role_additional_policies = {
			AmazonS3FullAccess = "arn:aws:iam::aws:policy/AmazonS3FullAccess",
			AutoScalingFullAccess = "arn:aws:iam::aws:policy/AutoScalingFullAccess",
			SecretsManagerReadWrite = "arn:aws:iam::aws:policy/SecretsManagerReadWrite",
			CloudWatchAgentServerPolicy = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy",
			EKSCustomPolicyForSecurityGroups = "arn:aws:iam::058264456163:policy/EKSCustomPolicyForSecurityGroups",
			AWSLoadBalancerControllerPolicy = "arn:aws:iam::058264456163:policy/AWSLoadBalancerControllerPolicy"
		}
	}

	eks_managed_node_groups = {

		node_group = {
			min_size     = 2
			max_size     = 6
			desired_size = 2
			}
	}

	access_entries = {
		ex_single = {
			principal_arn = "arn:aws:iam::058264456163:root"
			policy_associations = {
				ex = {
					policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" 
					access_scope = {
						type = "cluster"
					}
				}
			}
		}
		jenkins_server = {
			principal_arn = "arn:aws:iam::058264456163:role/Jenkins-IAM-Role"
			policy_associations = {
				ex = {
					policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
					access_scope = {
						type = "cluster"
					}
				}
			}
		}
	}
}
