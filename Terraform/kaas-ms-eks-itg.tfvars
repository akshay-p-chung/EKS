vpc_id="vpc-0713af9138278c2a2"

#subnet with more available addresses
private_subnets = ["subnet-04ed5296cc6028b5e", "subnet-0d9b33899d5277f1e"]

cluster_name = "kaas-ms-eks-itg"

kubernetes_version = "1.30"

ami_type = "AL2023_ARM_64_STANDARD

instance_types = ["m7g.2xlarge"]

#security_group_id = "sg-Beebeccb323a65d6a"

#security group for eks nodes

#security_group_id = ["sg-043f9871e8da9eaae"]

#tfstate_file = "terraform-eks/kaas-ms-eks-test.tfstate"