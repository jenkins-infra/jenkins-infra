# Profile to ensure `mirrorbits` CLI is installed
class profile::mirrorbits (
  String $mirrorbits_version,
  String $mirrorbits_docker_image_tag, # Assuming this image has the correct mirrorbits version. With an update per year we're safe
  String $mirrorbits_docker_image_name = 'dockerhubmirror.azurecr.io/jenkinsciinfra/mirrorbits',
  String $install_dir = '/usr/local/bin',
) {
  if $mirrorbits_docker_image_tag {
    $mirrorbits_docker_image = "${mirrorbits_docker_image_name}:${mirrorbits_docker_image_tag}"
    $check_mirrorbits_command = "/usr/bin/test -f ${install_dir}/mirrorbits && { ${install_dir}/mirrorbits version || true; } 2>/dev/null | /bin/grep --quiet ${mirrorbits_version}"

    if str2bool($facts['vagrant']) {
      # Our mirrorbits images are private and can't be reached from developer machines so we build the image
      $mirrorbits_docker_image_command = "/usr/bin/docker image build --tag=${mirrorbits_docker_image} https://github.com/jenkins-infra/docker-mirrorbits.git"
    } else {
      $mirrorbits_docker_image_command = "/usr/bin/docker image pull ${mirrorbits_docker_image}"
    }
    exec { "Ensure container image ${mirrorbits_docker_image} is present":
      require => [Class['profile::docker']],
      command => $mirrorbits_docker_image_command,
      unless  => "${check_mirrorbits_command} && /usr/bin/docker image ls | /bin/grep --quiet ${mirrorbits_docker_image}",
    }

    $container_name = 'mirrorbits-cli'

    exec { 'Install mirrorbits CLI':
      require => [Exec["Ensure container image ${mirrorbits_docker_image} is present"]],
      command => "/usr/bin/docker container rm --force ${container_name} && /usr/bin/docker container create --name ${container_name} ${mirrorbits_docker_image} && /usr/bin/docker container cp ${container_name}:/usr/bin/mirrorbits ${install_dir}/mirrorbits",
      unless  => $check_mirrorbits_command,
    }
  }
}
