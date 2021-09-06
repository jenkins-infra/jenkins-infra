---
source:
  kind: jenkins
  name: Get latest stable jenkins version
  spec:
    release: stable
    github:
      username: "{{ .github.username }}"
      token: "{{ requiredEnv .github.token }}"
conditions:
  defaultCiDockerImage:
    name: "Ensure default jenkins docker image name set to jenkins/jenkins"
    kind: yaml
    spec:
      file: hieradata/common.yaml
      key: "profile::buildmaster::docker_image"
      value: "jenkins/jenkins"
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
