vpc_id="vpc-08d07213d93086532"

#subnet with more available addresses
private_subnets = ["subnet-0f567cb1e05df30b9", "subnet-0f0db2303134914a7", "subnet-0d555ca56e92a2017", "subnet-0e9647ffbec785b26", "subnet-0559e8dde2ff21267"]

cluster_name = "eks-dev"

kubernetes_version = "1.30"

ami_type = "AL2023_x86_64_STANDARD"

instance_types = ["t2.micro"]
