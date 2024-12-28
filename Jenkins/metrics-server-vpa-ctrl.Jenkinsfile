pipeline {
	agent any
	parameters {
		choice(name: 'AWS_ACNT_ID', choices: ['058264456163'], description: 'Enter required AWS Account number here')
		choice(name: 'BRANCH', choices: ['main'], description: 'Branch Name')
		choice(name: 'EKS_NAME', choices: ['eks-dev', 'eks-pre-prod', 'eks-prod'], description: 'EKS Cluster Name')
	}
	environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION = 'us-east-1'
	}
	stages {
		stage('Cleaning Workspace') {
			steps {
				deleteDir()
					script {
					env.C_DIR = "VPA-${env.BUILD_NUMBER}"
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
		stage ('Install metric server') {
			steps {
				dir("${env.C_DIR}") {
					sh """
					kubectl apply -f Installations/metrics-server-components.yaml
					"""
				}
			}
		}
		stage ('Clone VPA Repo') {
			steps {
				dir("${env.C_DIR}/VPA/") {
					sh """
						git clone https://github.com/kubernetes/autoscaler.git
					"""
				}
			}
		}
		stage ('Install VPA') {
			steps {
				dir("${env.C_DIR}/VPA/") {
					script {
						sh """
							cd autoscaler
							git checkout vpa-release-1.2
							cd vertical-pod-autoscaler/hack
							chmod 777 vpa-up.sh
							./vpa-up.sh
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
