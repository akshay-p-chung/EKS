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
		POLICY_NAME="AWSLoadBalancerControllerIAMPolicy"
		POLICY_ARN="arn:aws:iam::${AWS_ACNT_ID}:policy/${POLICY_NAME}"
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
		stage('Create Namespace ingress-nginx') {
			steps {
				dir("${env.C_DIR}") {
					script {
						sh """
							echo "Checking if namespace 'ingress-nginx' exists..."

							# Check and create namespace if it doesn't exist
							if ! kubectl get namespace ingress-nginx >/dev/null 2>&1;
							then
								kubectl create namespace ingress-nginx
							else
								echo "Namespace 'ingress-nginx' already exists."
							fi
						"""
					}
				}
			}
		}
		stage('Install nginx ingress controller') {
			steps {
				dir("${env.C_DIR}") {
					script {
						sh """
							# Check if the Helm release exists
							if ! helm status nginx-ingress -n ingress-nginx >/dev/null 2>&1; 
							then
								echo "Helm release 'nginx-ingress' does not exist. Installing it now..."
								helm pull oci://ghcr.io/nginxinc/charts/nginx-ingress --version 1.4.1 --untar
								cd nginx-ingress
								helm install nginx-ingress . -n ingress-nginx --set controller.service.type=ClusterIP
							else
								echo "Helm release 'nginx-ingress' already exists. Skipping installation."
							fi
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
							
							# Check if policy exists, create it if not

							if ! aws iam get-policy --policy-arn ${POLICY_ARN} >/dev/null 2>&1; then
							aws iam create-policy \
								--policy-name ${POLICY_NAME} \
								--policy-document file://Policy/AWSLoadBalancerControllerIAMPolicy.json
							else
								echo "Policy ${POLICY_NAME} already exists"
							fi
							
							# Update the trust policy file with OIDC and Account ID
							sed -i "s/XXXXXXXXXXXXXXXXXXXXXXXXX/${OIDC_ID}/g; s/000000000000/${AWS_ACNT_ID}/g" Policy/AWSEKSLoadBalancerControllerRole-trust-policy.json
							
							# Check if role exists, create it if not
							if ! aws iam get-role --role-name ${ROLE_NAME} >/dev/null 2>&1; then
								aws iam create-role \
									--role-name ${ROLE_NAME} \
									--assume-role-policy-document file://Policy/AWSEKSLoadBalancerControllerRole-trust-policy.json
                        
							# Attach the policy to the role
								aws iam attach-role-policy \
									--policy-arn ${POLICY_ARN} \
									--role-name ${ROLE_NAME}
							else
								echo "Role ${ROLE_NAME} already exists"
							fi
						"""
					}
				}
			}
		}
		stage('Deploying AWS LB Controller') {
			steps {
				dir("${env.C_DIR}") {
					script {
						sh """

							# Check if the Helm release exists
							if ! helm status aws-load-balancer-controller -n kube-system >/dev/null 2>&1; 
							then

								# Update the service account YAML with account ID and cluster name
								sed -i "s/000000000000/${AWS_ACNT_ID}/g; s/EKS_NAME/${EKS_NAME}/g" Installations/sa-for-alb.yaml
                        
								# Add and update the Helm repo
								helm repo add eks https://aws.github.io/eks-charts
								helm repo update eks
                        
								# Deploy the AWS Load Balancer Controller
								helm install aws-load-balancer-controller eks/aws-load-balancer-controller -f Installations/sa-for-alb.yaml \
								  -n kube-system \
								  --set serviceAccount.create=false \
								  --set clusterName=${EKS_NAME}
							else
								echo "Helm release 'aws-load-balancer-controller' already exists in namespace 'kube-system'."
							fi
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
