# TerraformJenkins

# Download Terraform on the Jenkins server
  Move the downloaded Terraform executable to the /usr/bin location

# Prerequisites
  Install Jenkins
  Add packages related to the terrform after configuring Jenkins

# Global tool Configuration
  Provide the information regarding the terraform within the terraform section


# Pipeline within the jenkins
pipeline {
    agent any
    tools {
        terraform 'terraform'
    }

    stages {
        stage('Git Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/saikumar3115/TerraformJenkins.git'
            }
        }
        stage('terraform init') {
            steps {
                sh 'terraform init'
            }
        }
        stage('terraform fmt') {
            steps {
                sh 'terraform fmt'
            }
        }
        stage('terraform validate') {
            steps {
                sh 'terraform validate'
            }
        }
        stage('terraform plan') {
            steps {
                sh 'terraform plan'
            }
        }
        stage('terraform apply') {
            steps {
                sh 'terraform apply --auto-approve'
            }
        }
        stage('terraform destroy') {
            steps {
                sh 'terraform destroy --auto-approve'
            }
        }
    }
}
