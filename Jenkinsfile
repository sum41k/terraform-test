node {
  // Mark the code checkout 'stage'....
  sh label: '', script: 'export AWS_ACCESS_KEY_ID=${env.AWS_A_KEY_ID}'
  sh label: '', script: 'export AWS_SECRET_ACCESS_KEY=${env.AWS_SA_KEY}'
  stage 'Source' {
    git credentialsId: 'github_token', url: 'https://github.com/sum41k/terraform-test.git'
  }
  stage 'Stage Terraform Plan' {
    dir('/var/lib/jenkins/terraform-test') {
    sh label: '', script: 'terraform plan -out=./plan.txt'
    }
  }

  stage 'Archive Artifact' {
    dir('/var/lib/jenkins/terraform-test') {
    archiveArtifacts './plan.txt'
    }
  }

  stage 'Stage Terraform Apply'{
    input(message: "Should we continue?")
    sh label: '', script: 'terraform apply -auto-approve'
  }

}
