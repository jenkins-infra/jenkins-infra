{{ range $val := .playwright_consumers }}
---
name: Track Playwright (JS) version from production agents in {{ $val.repository }}

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
  # Hop 2: the Playwright (Linux) version baked into that packer-image release
  getPlaywrightVersionFromPackerImages:
    kind: yaml
    name: Get the NodeJS Linux version set in the production Packer images
    dependson:
      - getPackerImageDeployedVersion
    spec:
      file: https://raw.githubusercontent.com/jenkins-infra/packer-images/{{ source "getPackerImageDeployedVersion" }}/provisioning/tools-versions.yml
      key: $.playwright_version

conditions:
  check_playwright_npm:
    name: Test that the playwright version found exists on the NPM registry
    kind: npm
    sourceid: getPlaywrightVersionFromPackerImages
    spec:
      name: playwright

targets:
  default:
    name: Ensure package.json and package-lock.json are up to date with the playwright version found
    kind: shell
    disablesourceinput: true
    spec:
      # Since we use a file/checksum changedif, exit code is not caught. As such we use these tricks:
      # - If the `npm` command fail then delete one of the files specified to changedif to ensure target reports an error in the pipeline
      # - Redirect the `npm` command stderr to stdout to avoid hiding the error when it fails
      # (can be tested somewhere without the `npm` CLI in the PATH)
      command: npm install --package-lock-only playwright@{{ source "getPlaywrightVersionFromPackerImages" }} 2>&1 || rm -f package.json
      changedif:
        kind: file/checksum
        spec:
          files:
            - package-lock.json
            - package.json
    scmid: default

actions:
  default:
    kind: github/pullrequest
    scmid: default
    title: 'chore: Bump Playwright version to {{ source "getPlaywrightVersionFromPackerImages" }}'
    spec:
      labels:
        - dependencies
        - playwright
        - chore
        - updatecli

{{ end }}
