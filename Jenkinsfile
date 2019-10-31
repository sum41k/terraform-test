node {
  // Mark the code checkout 'stage'....
  sh 'export AWS_ACCESS_KEY_ID=${env.AWS_A_KEY_ID}'
  sh 'export AWS_SECRET_ACCESS_KEY=${env.AWS_SA_KEY}'
  stage 'Stage Terraform Plan' {
    sh 'terraform plan -out=./plan.txt'
  }

  // Checkout code from repository and update any submodules


  stage 'Stage Terraform Apply'{
    input(message: "Should we continue?")
    sh 'terraform apply -auto-approve'
  }

}
