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
		POLICY_ARN = "arn:aws:iam::${params.AWS_ACNT_ID}:policy/eks_cluster_autoscaler_policy"
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
		stage('Create IAM Role for Cluster Autoscaler'){
			steps {
				dir("${env.C_DIR}") {
					script{
						sh"""
							echo "OIDC_ID: ${params.OIDC_ID}"
							echo "AWS_ACNT_ID: ${params.AWS_ACNT_ID}"
							sed -i 's/XXXXXXXXXXXXXXXXXXXXXXXXX/${OIDC_ID}/g; s/000000000000/${AWS_ACNT_ID}/g' Policy/EKSClusterAutoScaler-trust-policy.json
							aws iam create-role --role-name ${ROLE_NAME} --assume-role-policy-document file://Policy/EKSClusterAutoScaler-trust-policy.json							
							aws iam attach-role-policy --policy-arn ${POLICY_ARN} --role-name ${ROLE_NAME}
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
							#Edit the manifest file to change the annotation value from "false" to "true"
							sed -i 's/<YOUR CLUSTER NAME>/${EKS_NAME}/g' cluster-autoscaler-deploy.yaml
							
							#Apply the updated manifest file
							kubectl apply -f cluster-autoscaler-deploy.yaml
						
							#update service account with IAM role
							kubectl annotate serviceaccount cluster-autoscaler eks.amazonaws.com/role-arn:arn:aws:iam::${AWS_ACNT_ID}:role/${ROLE_NAME} --namespace kube-system
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
