pipeline {
    agent any

    environment {
        AWS_REGION = "ap-southeast-2"
        AWS_ACCOUNT_ID = "971422685558"
        ECR_REPO = "s3-rds-repo"
        IMAGE_TAG = "latest"
    }

    stages {
        stage('Clone Repo') {
            steps {
                git 'https://github.com/YashHonkalse/S3-RDS.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG .
                """
            }
        }

        stage('Login to AWS ECR') {
            steps {
                sh """
                aws ecr get-login-password --region $AWS_REGION | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
                """
            }
        }

        stage('Push Image to ECR') {
            steps {
                sh """
                docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$ECR_REPO:$IMAGE_TAG
                """
            }
        }

        stage('Terraform Init & Plan') {
            steps {
                sh """
                cd terraform
                terraform init
                terraform plan -out=tfplan
                """
            }
        }

        stage('Manual Approval for Terraform Apply') {
            steps {
                script {
                    def userInput = input(
                        id: 'confirmApply',
                        message: 'Do you want to apply the Terraform changes?',
                        parameters: [
                            choice(choices: ['YES', 'NO'], description: 'Select YES to proceed, NO to cancel', name: 'Confirm')
                        ]
                    )

                    if (userInput == 'YES') {
                        echo '✅ Proceeding with Terraform Apply...'
                    } else {
                        error('❌ Terraform Apply Aborted!')
                    }
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                sh """
                cd terraform
                terraform apply -auto-approve tfplan
                """
            }
        }

        stage('Invoke Lambda Function') {
            steps {
                sh """
                aws lambda invoke --function-name s3-to-rds-lambda output.txt
                cat output.txt
                """
            }
        }
    }
}
