pipeline {
	agent any
	parameters {
		choice(name: 'AWS_ACNT_ID', choices: ['943535361612'], description: 'Enter required AllS Account number here')
		string(name: 'BRANCH', defaultValue: '')
		string(name: 'EKS_NAME', defaultValue: '', description: 'EKS cluster name')
		string(name: 'OIDC_ID', defaultValue:", description: 'EKS OIDC ID')
	}
	environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION = 'us-east-2'
	ROLE_NAME = "${params.EKS_NAME}-cluster-autoscaler-role"
	POLICY_NAME="AmazonEKSClusterAutoscalerPolicy"
	POLICY_ARN="arn:aws:iam::${AWS_ACNT_ID}:policy/${POLICY_NAME}"
	}
	stages{
		stage('Cleaning Workspace') {
			steps {
				script {
					deleteDir()
					env.C_DIR = "AutoScaler-${env.BUILD_NUMBER}"
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
		stage('Create IAM Role for Cluster Autoscaler') {
			steps {
				dir("${env.C_DIR}") {
					script {
						sh """
							echo "OIDC_ID: ${params.OIDC_ID}"
							echo "AWS_ACNT_ID: ${params.AWS_ACNT_ID}"

							# Check if policy exists, create it if not
							if ! aws iam get-policy --policy-arn ${POLICY_ARN} >/dev/null 2>&1; then
							aws iam create-policy \
								--policy-name ${POLICY_NAME} \
								--policy-document file://Policy/cluster-autoscaler-policy.json
							else
								echo "Policy ${POLICY_NAME} already exists"
							fi

							# Update the trust policy file with OIDC and Account ID
							sed -i 's/XXXXXXXXXXXXXXXXXXXXXXXXX/${OIDC_ID}/g; s/000000000000/${AWS_ACNT_ID}/g' Policy/EKSClusterAutoScaler-trust-policy.json
                    
							# Check if role exists, create it if not
							if ! aws iam get-role --role-name ${ROLE_NAME} >/dev/null 2>&1; then
								aws iam create-role \
									--role-name ${ROLE_NAME} \
									--assume-role-policy-document file://Policy/EKSClusterAutoScaler-trust-policy.json
                        
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

		stage('Deploy Cluster Autoscaler'){
			steps{
				dir("${env.C_DIR}/Installations/"){
					script {
						sh"""
							# Update the manifest file and apply it
							sed -i 's/<YOUR CLUSTER NAME>/${EKS_NAME}/g' cluster-autoscaler-autodiscover.yaml
							kubectl apply -f cluster-autoscaler-deploy.yaml
						
							# Update service account with the IAM role
							kubectl annotate serviceaccount cluster-autoscaler eks.amazonaws.com/role-arn=arn:aws:iam::${AWS_ACNT_ID}:role/${ROLE_NAME} --namespace kube-system
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
