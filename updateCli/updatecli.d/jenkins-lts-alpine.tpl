---
source:
  kind: dockerDigest
  name: Get latest jenkins/jenkins:lts-jdk11 docker digest
  spec:
    image: "jenkins/jenkins"
    tag: "lts"

conditions:
  defaultCiDockerImage:
    name: "Ensure default jenkins docker image name set to jenkins/jenkins@sha256"
    kind: yaml
    spec:
      file: hieradata/common.yaml
      key: "profile::buildmaster::docker_image"
      value: "jenkins/jenkins@sha256"
    scm:
      github:
        user: "{{ .github.user }}" 
        email: "{{ .github.email }}" 
        owner: "{{ .github.owner }}" 
        repository: "{{ .github.repository }}" 
        token: "{{ requiredEnv .github.token }}" 
        username: "{{ .github.username }}" 
        branch: "{{ .github.branch }}" 

targets:
  imageTag:
    name: "Update Docker Image Digest for jenkins/jenkins:lts"
    kind: yaml
    postfix: " #tag: lts"
    spec:
      file: "hieradata/common.yaml"
      key: "profile::buildmaster::docker_tag"
    scm:
      github:
        user: "{{ .github.user }}" 
        email: "{{ .github.email }}" 
        owner: "{{ .github.owner }}" 
        repository: "{{ .github.repository }}" 
        token: "{{ requiredEnv .github.token }}" 
        username: "{{ .github.username }}" 
        branch: "{{ .github.branch }}" 
