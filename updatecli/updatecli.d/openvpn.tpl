---
source:
  kind: dockerDigest
  name: Get latest jenkinsciinfra/openvpn:latest docker digest
  spec:
    image: "jenkinsciinfra/openvpn"
    tag: "latest"

conditions:
  defaultCiDockerImage:
    name: "Ensure default openvpn docker image name set to jenkinsciinfra/openvpn@sha256"
    kind: yaml
    spec:
      file: hieradata/common.yaml
      key: "profile::openvpn::image"
      value: "jenkinsciinfra/openvpn@sha256"
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
    name: "Update Docker Image Digest for jenkinsciinfra/openvpn:latest"
    kind: yaml
    spec:
      file: "hieradata/common.yaml"
      key: "profile::openvpn::image_tag"
    scm:
      github:
        user: "{{ .github.user }}" 
        email: "{{ .github.email }}" 
        owner: "{{ .github.owner }}" 
        repository: "{{ .github.repository }}" 
        token: "{{ requiredEnv .github.token }}" 
        username: "{{ .github.username }}" 
        branch: "{{ .github.branch }}" 
