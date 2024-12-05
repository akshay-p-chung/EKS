#EKS

module "eks" {
	source "terraform-aws-modules/eks/aws"

	cluster name    = var.cluster name
	cluster_version = var.kubernetes_version

	iam_role_additional policies = {
		ElasticLoadBalancingFullAccess "arniaws:iam::aws:policy/ElasticLoad BalancingFullAccess"
	}
	
	vpc_id = var.vpc_id
	subnet_ids = var.private_subnets

	enable_irsa = true
	cluster_endpoint_public_access = true

	eks_managed_node_group_defaults = {
		ami_type       = var.ami_type
		instance_types = var.instance_types
		create_node_security_group = false
			iam_role_additional_policies = {
				Amazon S3FullAccess "arn:aws:iam::aws:policy/Amazon53FullAccess",
				AutoScalingFullAccess "arn:aws:iam::aws:policy/AutoScalingFullAccess",
				SecretsManagerReadWrite = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
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
			principal_arn = "arn:aws:iam::943535361612:role/ADMIN"
			policy_associations = {
				ex = {
					policy_arn "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy" 
					access_scope {
						type = "cluster"
					}
				}
			}
		}
		jenkins_server = {
			principal_arn = "arn:aws:iam::943535361612:role/Jenkins-iam-role"
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