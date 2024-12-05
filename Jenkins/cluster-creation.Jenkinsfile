pipeline {
	agent any
	parameters {
		choice(name: 'tfvars', choices: ['values/eks-dev.tfvars', 'values/eks-pre-prod.tfvars', 'values/eks-prod.tfvars'], description: 'tfvars file for the cluster')
		choice(name: 'BACKEND', choices: ['backend/backend-dev.hcl', 'backend/backend-pre-prod.hcl', 'backend/backend-prod.hcl'], description: 'backend hcl file for the cluster')
		choice(name: 'BRANCH', choices: ['main'], description: 'branch to clone the terraform module')
		choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Action to be taken')
	}

	environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION = 'us-east-2'
	}

	stages{
		stage('Cleaning Workspace') {
			steps {
				script {
					deleteDir()
					env.C_DIR= "Cluster-${env.BUILD_NUMBER}"
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
		stage('Terraform init'){
			steps{
				dir("$env.C_DIR") {
					script{	
						dir('Terraform'){
							sh """
								echo "terraform init -var-file-${tfvars} -backend-config=${BACKEND}"
								terraform init reconfigure -var-file=${tfvars} -backend-config=${BACKEND}
							"""
						}
					}
				}
			}
		}
		stage('Terraform plan'){
			steps{
				dir("$env.C_DIR") {
					script{
						dir('Terraform') {
							sh """
								echo "terraform plan -var-file=${tfvars}"
								terraform plan -var-file=${tfvars}
							"""
						}
						input(message: "Approve?", ok: "proceed")
					}
				}
			}
		}
		stage('Terraform apply/destroy'){
			steps{
				dir("$env.C_DIR") {
					script{
						dir('Terraform'){
							sh """
								echo "terraform ${ACTION} -var-file=${tfvars} --auto-approve"
								terraform ${ACTION} -var-file=${tfvars} --auto-approve
							"""
						}
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
