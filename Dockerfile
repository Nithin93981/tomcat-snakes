# Starter pipeline
# Start with a minimal pipeline that you can customize to build and deploy your code.
# Add steps that build, run tests, deploy, and more:
# https://aka.ms/yaml

trigger:
- master123

pool: LinuxAgentPool
  #vmImage: ubuntu-latest

steps:
- script: echo "Testing the pipelines"
  displayName: 'pipeline testing'

- script: echo  $(Build.BuildId)
  displayName: 'display the build id'

- script: ls -al && pwd
  displayName: 'list the files & current directory'  

# - script: sudo apt update  && sudo apt install -y openjdk-8-jdk && java -version 
#   displayName: 'downloading and java && showing version'

- script: ls -al && chmod 700 build.sh && ./build.sh && ls -al
  displayName: 'run the build script'

- script: ls -al &&  mv ROOT.war ROOT$(Build.BuildId).war && ls -al 
  displayName: 'listing files and renaming root.war'
  
- task: CopyFiles@2  
  inputs:
    Contents: 'ROOT$(Build.BuildId).war' 
    TargetFolder: '$(Build.ArtifactStagingDirectory)'
    OverWrite: true
  displayName: 'copying war file to ArtifactStagingDirectory'  

- script: ls -al $(Build.ArtifactStagingDirectory) 
  displayName: 'List Build Artifact staging folder'

- task: S3Upload@1
  inputs:
    awsCredentials: 'azure-s3-connection'
    regionName: 'us-east-1'
    bucketName: 'awsnithin.xyz'
    sourceFolder: '$(Build.ArtifactStagingDirectory)'
    globExpressions: 'ROOT$(Build.BuildId).war'
  displayName: 'upload artifact to s3'

- task: Docker@2
  inputs:
    containerRegistry: 'azure-docker-connection'
    repository: 'suramnithin/azuredocker'
    command: 'buildAndPush'
    Dockerfile: '**/Dockerfile'
  displayName: 'creating and pushing docker image to docker hub'  
  continueOnError: true


- script: |
    docker build -t 44suramnithin:$(Build.BuildId) .
    docker tag 44suramnithin:$(Build.BuildId) 465195487122.dkr.ecr.us-east-1.amazonaws.com/44suramnithin:$(Build.BuildId)
    aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 465195487122.dkr.ecr.us-east-1.amazonaws.com
    docker push 465195487122.dkr.ecr.us-east-1.amazonaws.com/44suramnithin:$(Build.BuildId)
  displayName: 'Build, Tag, Login, and Push Docker Image to AWS ECR'




# - task: ECRPushImage@1
#   inputs:
#     awsCredentials: 'azure-s3-connection'
#     regionName: 'us-east-1'
#     imageSource: 'imagename'
#     sourceImageName: 'suramnithin/azuredocker'
#     sourceImageTag: '$(Build.BuildId)'
#     repositoryName: '44suramnithin'
#     pushTag: '465195487122.dkr.ecr.us-east-1.amazonaws.com/44suramnithin:$(Build.BuildId)

# - script: cd /home/nithin/myagent/_work/1/ &&  rm -rf s/ && ls -al
#   displayName: 'Removing files'
