pipeline {
	agent any
	parameters {
		choice (name: 'AWS_ACNT_ID', choices: ['058264456163'], description: 'Enter required AWS Account number here')
		choice (name: 'ServiceBranch', choices: ['main'], description: '')
		extendedChoice(description:'', multiSelectDelimiter:'', name: 'ServiceName', quoteValue: false, saveJOSNParameterToFile: false, type: 'PT_CHECKBOX', value: 'All,sample-app,service-one,service-two', visibleItemCount: 3)
		choice (name: 'Environment', choices: ['dev', 'itg'], description: 'Environment to Deploy')
	}
	environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION = 'us-east-1'
		BUILD_TAG = "${ServiceBranch}-${env.BUILD_NUMBER}"
	}
	stages {
		stage ('Cleaning Workspace') {
			steps {
				script {
					deleteDir()
					env.docker_img_created = false
					env.C_DIR = "Deployment-${env.BUILD_NUMBER}"
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
		stage('Docker Image Creation & push to ECR') {
			steps {
				dir("${env.C_DIR}") {
					script {
						sh"""
							echo ${ServiceName}
							if [ "$ServiceName" == "All" ]
							then
								ServiceName="sample-app,service-one,service-two"
							fi
							for i in ${ServiceName}
							do
								aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin ${AWS_ACNT_ID}.dkr.ecr.us-east-1.amazonaws.com
								docker build -t $i $i/
								docker tag $i:latest ${AWS_ACNT_ID}.dkr.ecr.us-east-1.amazonaws.com
								docker push ${AWS_ACNT_ID}.dkr.ecr.us-east-1.amazonaws.com/kaas-dev/$i:${BUILD_TAG}
							done
						"""
						env.docker_img_created = true
					}
				}
			}
		}
		stage('Helm Deployment') {
			steps {
				dir("${env.C_DIR}") {
					script {
						sh"""
							kubectl config use-context arn:aws:eks:us-east-1:${AWS_ACNT_ID}:cluster/eks-${Environment}
							if [ "${ServiceName}" == "All" ]
							then
								ServiceName="sample-app,service-one,service-two"
							fi
							for i in ${ServiceName}
							do
								helm upgrade --install $i helm-config/$i --set image.repository=${AWS_ACNT_ID}.dkr.ecr.us-east-1.amazonaws.com/project/$i --set image.tag=${BUILD_TAG} -f helm-config/values.yaml
							done
						"""
					}
				}
			}
		}
	}
	post {
		always {
			dir("${env.C_DIR}") {
				script {
					echo "$docker_img_created"
						if ("$docker_img_created" 'true') {
							sh"""
							ls -ltr
								if [ $ServiceName == "All" ]
								then
										ServiceName="sample-app,service-one,service-two"
								fi
								for i in $ServiceName
								do
									docker rmi ${AWS_ACNT_ID}.dkr.ecr.us-east-1.amazonaws.com/kaas-dev/${BUILD_TAG}
									docker rmi $i:latest
								done
							"""
						}
						else {
							echo "Docker image not created to clean and delete"
						}
				}
			}
		deleteDir()
		}
	}
}
