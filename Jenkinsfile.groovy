node {
  stage ('Source') {
    git credentialsId: 'github_token', url: 'https://github.com/sum41k/terraform-test.git'
  }
  stage ('Stage Terraform Plan') {
    dir('/var/lib/jenkins/workspace/terraform-test') {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding',
        accessKeyVariable: 'AWS_ACCESS_KEY_ID',
        credentialsId: 'terraform-test',
        secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          sh """
            terraform init
            terraform plan -out=./plan.plan
          """
        }
    }
  }

  stage ('Archive Artifact') {
    dir('/var/lib/jenkins/workspace/terraform-test') {
    archiveArtifacts 'plan.plan'
    }
  }

  stage ('Stage Terraform Apply'){
    input(message: "Should we apply this plan?")
    sh label: '', script: 'terraform apply "plan.plan"'
  }

}
