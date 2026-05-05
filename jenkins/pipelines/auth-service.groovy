// jenkins/pipelines/auth-service.groovy
// Triggered by: webhook from GitHub on push to services/auth-service/**
pipelineJob('shopsecure-auth-service') {
  definition {
    cpsScmFlowDefinition {
      scm {
        git {
          remote { url('https://github.com/YOUR_ORG/shopsecure.git') }
          branches('*/main')
        }
      }
      scriptPath('jenkins/Jenkinsfile')
    }
  }
  parameters {
    stringParam('SERVICE_NAME', 'auth-service', 'Service to build and deploy')
    stringParam('REPO_URL', 'https://github.com/YOUR_ORG/shopsecure.git', 'Source repository')
    stringParam('AWS_ACCOUNT_ID', '', 'AWS Account ID for ECR registry')
  }
  triggers {
    githubPush()
    pollSCM('H/5 * * * *')
  }
  logRotator { numToKeep(20) }
}
