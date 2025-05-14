pipeline {
    agent any
    
    environment {
        // Reference your Azure Service Principal credentials from Jenkins
        AZURE_CREDENTIALS_ID = 'az-sp' // Match the ID you used when creating credentials
        PATH = "/opt/homebrew/bin:$PATH"
        
        // Azure Terraform Backend Configuration
        TF_STATE_RESOURCE_GROUP = "Dev-RG"
        TF_STATE_STORAGE_ACCOUNT = "ttfstatesa"
        TF_STATE_CONTAINER = "tfstate"
        TF_STATE_KEY = "terraform.tfstate"
        
        // Environment specific variables (customize as needed)
        LOCATION = "eastus"
    }
    
    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
            }
        }

          stage('Azure Login') {
            steps {
                // Authenticate using the Azure Service Principal
                withCredentials([azureServicePrincipal(AZURE_CREDENTIALS_ID)]) {
                    sh '''
                    az login --service-principal \
                        -u $AZURE_CLIENT_ID \
                        -p $AZURE_CLIENT_SECRET \
                        --tenant $AZURE_TENANT_ID
                    az account set --subscription $AZURE_SUBSCRIPTION_ID
                    '''
                }
            }
        }
//# Add this debug stage to your Jenkinsfile
stage('Verify Files') {
    steps {
        sh '''
        echo "Current directory: $(pwd)"
        ls -la
        mkdir terraform
        cp *.tf terraform/
        cd terraform
        pwd
        ls -al
        '''
    }
} 

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    withCredentials([azureServicePrincipal(AZURE_CREDENTIALS_ID)]) {
                        sh '''
                        export ARM_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID
                        export ARM_CLIENT_ID=$AZURE_CLIENT_ID
                        export ARM_CLIENT_SECRET=$AZURE_CLIENT_SECRET
                        export ARM_TENANT_ID=$AZURE_TENANT_ID
                        
                        terraform init \
                            -backend-config="resource_group_name=${TF_STATE_RESOURCE_GROUP}" \
                            -backend-config="storage_account_name=${TF_STATE_STORAGE_ACCOUNT}" \
                            -backend-config="container_name=${TF_STATE_CONTAINER}" \
                            -backend-config="key=${TF_STATE_KEY}" \
                            -input=false
                        '''
                    }
                }
            }
        }
        
        stage('Terraform Validate') {
            steps {
                dir('terraform') {
                    sh 'terraform validate'
                }
            }
        }
        
        stage('Terraform Plan') {
            steps {
                dir('terraform') {
                    withCredentials([azureServicePrincipal(AZURE_CREDENTIALS_ID)]) {
                        sh '''
                        export ARM_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID
                        export ARM_CLIENT_ID=$AZURE_CLIENT_ID
                        export ARM_CLIENT_SECRET=$AZURE_CLIENT_SECRET
                        export ARM_TENANT_ID=$AZURE_TENANT_ID
                        
                        terraform plan -input=false -out=tfplan
                        terraform show -no-color tfplan > tfplan.txt
                        '''
                    }
                    archiveArtifacts artifacts: 'terraform/tfplan', onlyIfSuccessful: true
                    archiveArtifacts artifacts: 'terraform/tfplan.txt', onlyIfSuccessful: true
                    
                    // Optional: Publish plan output
                    sh 'cat tfplan.txt'
                }
            }
        }
        
        stage('Manual Approval') {
            steps {
               timeout(time: 1, unit: 'HOURS') {
                    input message: 'Review the plan above. Proceed with Terraform Apply?', ok: 'Apply'
                }
            }
        }
        
        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    withCredentials([azureServicePrincipal(AZURE_CREDENTIALS_ID)]) {
                        sh '''
                        export ARM_SUBSCRIPTION_ID=$AZURE_SUBSCRIPTION_ID
                        export ARM_CLIENT_ID=$AZURE_CLIENT_ID
                        export ARM_CLIENT_SECRET=$AZURE_CLIENT_SECRET
                        export ARM_TENANT_ID=$AZURE_TENANT_ID
                        
                        terraform apply -input=false -auto-approve
                        '''
                    }
                }
            }
        }
        
        stage('Output Results') {
            steps {
                dir('terraform') {
                    sh 'terraform output -json > terraform_output.json'
                    archiveArtifacts artifacts: 'terraform/terraform_output.json', onlyIfSuccessful: true
                }
            }
        }
    }
    
    post {
        always {
            // Clean up Azure CLI session
            sh 'az logout || true'
            cleanWs()
        }
        success {
            echo 'Terraform execution completed successfully'
        }
        failure {
            mail to: 'rahul.damalas@gmail.com',
                 subject: "Failed Pipeline: ${currentBuild.fullDisplayName}",
                 body: "Azure Terraform pipeline failed. Check ${env.BUILD_URL}"
        }
    }
}
