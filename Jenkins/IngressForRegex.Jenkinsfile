pipeline {
	agent any
	parameters {
		choice(name: 'AWS_ACNT_ID', choices: ['058264456163'], description: 'Enter required AWS Account number here')
		choice(name: 'BRANCH', choices: ['main'], description: 'Branch Name')
		choice(name: 'EKS_NAME', choices: ['eks-dev', 'eks-pre-prod', 'eks-prod'], description: 'EKS Cluster Name')
		string(name: 'OIDC_ID', defaultValue:"", description: 'EKS OIDC ID')
	}
	
	environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION = 'us-east-2'
		ROLE_NAME = "${params.EKS_NAME}-AmazonEKSLoadBalancerControllerRole"
		POLICY_ARN = "arn:aws:lam::${params.AWS_ACNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy"
	}
	
	stages{
		stage('Cleaning Workspace') {
			steps {
				script {
					deleteDir()
					env.C_DIR = "Ingress-${env.BUILD_NUMBER}"
				}
			}
		}
		stage('Code Clone') {
			steps{
				dir("$env.C_DIR") {
					script{
						git branch: '${BRANCH}', url: 'https://github.com/akshay-p-chung/EKS.git'
					}
				}
			}
		}
		stage('Login to AWS EKS Cluster'){
			steps{
				dir("${env.C_DIR}") {
					script{
						sh"""
							aws eks update-kubeconfig --name ${EKS_NAME} --region us-east-1
						"""
					}
				}
			}
		}
		stage('Create namespace ingress-nginx'){
			steps{
				dir("${env.C_DIR}") {
					script{
						sh"""
							kubectl create namespace ingress-nginx
						"""
					}
				}
			}
		}
		stage('Install nginx ingress controller'){
			steps{
				dir("${env.C_DIR}") {
					script {
						sh"""
							helm pull oci://ghcr.io/nginxinc/charts/nginx-ingress --version 1.4.1 --untar
							cd nginx-ingress
							helm install nginx-ingress . -n ingress-nginx --set controller.service.type=ClusterIP
						"""
					}
				}
			}
		}
		stage('Create AmazonEKSLoadBalancerControllerRole'){
			steps{
				dir("${env.C_DIR}") {
					script{
						sh"""
							echo "OIDC_ID: ${params.OIDC_ID}"
							echo "AWS_ACNT_ID: ${params.AWS_ACNT_ID}"
							sed -i "s/XXXXXXXXXXXXXXXXXXXXXXXXX/${OIDC_ID}/g; s/000000000000/${AWS_ACNT_ID}/g" Policy/AWSEKSLoadBalancerControllerRole-trust-policy.json
							aws iam create-role --role-name ${ROLE_NAME} --assume-role-policy-document file://Policy/AWSEKSLoadBalancerControllerRole-trust-policy.json
							aws iam attach-role-policy --policy-arn ${POLICY_ARN} --role-name ${ROLE_NAME}
						"""
					}
				}
			}
		}
		stage('Deploying AWS LB Controller'){
			steps{
				dir("${env.C_DIR}") {
					script{
						sh"""
							helm repo add eks https://aws.github.io/eks-charts 
							helm repo update eks
							helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
							  -n kube-system \
							  --set serviceAccount.create=true \
							  --set serviceAccount.name=aws-load-balancer-controller \
							  --set serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn=arn:aws:iam::${AWS_ACNT_ID}:role/${EKS_NAME}-AWSLoadBalancerControllerRole
						"""	  
					}
				}
			}
		}
		stage('Wait'){
			steps{
				// Sleep for 60 seconds to wait for the pod to be up and running
				sleep time: 1, unit: 'MINUTES'
			}
		}
		stage('Connect AWS LB Controller with Nginx Ingress Controller') {
			steps{
				dir("${env.C_DIR}/Installations/") {
					script {
						sh"""
							kubectl apply -f alb-nginx-ingress-connect.yaml
						"""
					}
				}
			}
		}
		stage('Wait again') {
			steps{
				// Sleep for 60 seconds to wait for the pod to be up and running
				sleep time: 1, unit: 'MINUTES'
			}
		}
		stage('Apply Frontier Ingress Rule') {
			steps{
				dir("${env.C_DIR}/Installations/") {
					script {
						sh"""
							kubectl apply -f frontier-ingress.yaml
						"""
					}
				}
			}
		}
	}
	post {
		always {
			deleteDir()
		}
	}
}
