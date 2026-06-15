{{ range $val := .nodejs_consumers }}
---
name: Track NodeJS version from production agents in {{ $val.repository }}

scms:
  default:
    kind: github
    spec:
      user: "{{ $.github.user }}"
      email: "{{ $.github.email }}"
      owner: "{{ $.github.owner }}"
      repository: {{ $val.repository }}
      token: "{{ requiredEnv $.github.token }}"
      username: "{{ $.github.username }}"
      branch: main

sources:
  # Hop 1: which packer-image version is deployed in production
  getPackerImageDeployedVersion:
    kind: yaml
    name: Retrieve the current version of the Packer images used in production
    spec:
      file: hieradata/common.yaml
      key: $.profile::jenkinscontroller::jcasc.agent_images.azure_vms_gallery_image.version
  # Hop 2: the NodeJS (Linux) version baked into that packer-image release
  getNodeJSVersionFromPackerImages:
    kind: yaml
    name: Get the NodeJS Linux version set in the production Packer images
    dependson:
      - getPackerImageDeployedVersion
    spec:
      file: https://raw.githubusercontent.com/jenkins-infra/packer-images/{{ source "getPackerImageDeployedVersion" }}/provisioning/tools-versions.yml
      key: $.nodejs_linux_version

targets:
  default:
    name: Bump NodeJS version in {{ $val.repository }} .tool-versions
    kind: file
    sourceid: getNodeJSVersionFromPackerImages
    scmid: default
    transformers:
      - addprefix: "nodejs "
    spec:
      file: .tool-versions
      matchpattern: 'nodejs .*'

actions:
  default:
    kind: github/pullrequest
    scmid: default
    title: Bump NodeJS version in {{ $val.repository }} .tool-versions
    spec:
      labels:
        - dependencies

{{ end }}
