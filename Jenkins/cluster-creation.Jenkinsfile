pipeline {
	agent any
	parameters {
		choice(name: 'AWS_ACNT_ID', choices: ['943535361612'], description: 'Enter required AllS Account number here')
		choice(name: 'ENV', choices: ['dev', 'itg'], description: 'Environment of the cluster')
		choice(name: 'tfvars', choices: ['values/kaas-ms-eks-dev.tfvars', 'values/kaas-ms-eks-itg.tfvars'], description: 'tfvars file for the cluster')
		choice(name: 'BACKEND', choices: ['backend/backend-dev.hcl', 'backend/backend-itg.hcl'], description: 'backend hcl file for the cluster')
		choice(name: 'BRANCH', choices: ['SC-8.6_release'], description: 'backend hcl file for the cluster')
		choice(name: 'ACTION', choices: ['apply', 'destroy'], description: 'Action to be taken')
	}

	environment {
		REGION = 'us-east-1'
		jenkinsrole = "Jenkins-iam-role" // Just the name of Role
		jenkinsroleaccount = "${params.AWS_ACNT_ID}" //Account Number
		jenkinsrolesessionname = "Jenkins-session" //Optional value
		roleduration = 3600 //limit to 1 hour
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
						git branch: '${BRANCH}', credentialsId: 'kaas-git-credentials', url: 'https://github.azc.ext.hp.com/CSS-IT-Integration/hp-kaas-devops.git'
					}
				}
			}
		}
		stage("Terraform init'){
			steps{
				dir("$env.C_DIR") {
					script{	
						dir('Terraform'){
							sh """
								echo "terraform init -var-file-$(tfvars) -backend-config-$(BACKEND)"
								terraform init reconfigure -var-file=$(tfvars) -backend-config-S(BACKEND)
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
								echo "terraform $ACTION-var-file=${tfvars} --auto-approve"
								terraform $ACTION-var-file=${tfvars} --auto-approve
						}
					}
				}
			}
		}
		stage (Wait){
			steps{
			// Sleep for 60 seconds to wait for the pod to be up and running
			sleep time: 1, unit: 'MINUTES"
			}
		}
		stage('Login to AWS EKS Cluster'){
			steps {
				dir("Senv.C_DIR") {
					script{
						sh """
							aws eks update-kubeconfig --name kaas-ms-eks-$(ENV) --region us-east-1
					}
				}
			}
		}
		stage("Generate Consul Cert Secret'){
			steps{
				dir("$(env.C_DIR)/Installations") {
					script {
						sh """
							kubectl create secret generic kaas-${ENV}-consul-cert --from-file=kaas-${ENV}-consul-cert=kaas-consul-itg.corp.hpicloud.net.crt
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