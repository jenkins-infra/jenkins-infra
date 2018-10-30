# Deploy evergreen_gateway
#   Class: profile::kubernetes::resources::evergreen_gateway
#
#   This class deploy an sshd service that can be used as gateway for evergreen contributors
#
#   Parameters:
#     $clusters:
#       clusters contains a list of cluster information.
#
#     $image_tag:
#       Define tag used for nginx docker image
#
#     $db_host:
#       Define evergreen database hostname
#
#     $db_port:
#       Define evergreen database port
#
#     $db_user:
#       Define evergreen database user, it should be a read-only user
#
#     $db_name:
#       Define evergreen database name
#
#     $db_pass:
#       Define evergreen database password
#

class profile::kubernetes::resources::evergreen_gateway (
  Array $clusters = $profile::kubernetes::params::clusters,
  String $image_tag = '',
  String $db_host   = '',
  String $db_port   = '5432',
  String $db_user   = '',
  String $db_name   = '',
  String $db_pass   = ''
) inherits profile::kubernetes::params {

  include ::stdlib
  require profile::kubernetes::resources::evergreen
  require profile::kubernetes::kubectl

  $clusters.each | $cluster | {
    $context = $cluster['clustername']

    file { "${profile::kubernetes::params::resources}/${context}/evergreen_gateway":
      ensure => 'directory',
      owner  => $profile::kubernetes::params::user,
    }

    # Template evergreen profile file
    $profile = @("PROFILE"/L$)
      export DB_HOST=${db_host}
      export DB_PORT=${db_port}
      export DB_USER=${db_user}
      export DB_NAME=${db_name}
      export DB_PASS=${db_pass}

      echo "\${DB_HOST}:\${DB_PORT}:\${DB_NAME}:\${DB_USER}:\${DB_PASS}" > \${HOME}/.pgpass
      chmod 0600 \${HOME}/.pgpass

      psql -U \${DB_USER} -d \${DB_NAME} -h \${DB_HOST}
      | PROFILE


    profile::kubernetes::apply{ "evergreen_gateway/secret.yaml on ${context}":
      context    => $context,
      resource   => 'evergreen_gateway/secret.yaml',
      parameters => {
        'profile' => base64('encode', $profile, 'strict')
      }
    }

    profile::kubernetes::apply{ "evergreen_gateway/service.yaml on ${context}":
      context  => $context,
      resource => 'evergreen_gateway/service.yaml'
    }

    profile::kubernetes::apply{ "evergreen_gateway/deployment.yaml on ${context}":
      context    => $context,
      parameters => {
        'image_tag' => $image_tag
      },
      resource   => 'evergreen_gateway/deployment.yaml'
    }

    profile::kubernetes::reload { "evergreen_gateway pods on ${context}":
      context    => $context,
      app        => 'gateway',
      namespace  => 'evergreen',
      depends_on => [
        'evergreen_gateway/secret.yaml',
      ]
    }
  }
}
