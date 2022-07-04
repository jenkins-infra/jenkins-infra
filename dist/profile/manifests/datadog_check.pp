# Assemble fragments into datadog checker configuration files
#
define profile::datadog_check (
  $ensure    = present,
  $checker   = undef,
  $source    = undef,
  $content   = undef,
) {
  $target ="${datadog_agent::params::conf_dir}/${checker}.yaml"

  include datadog_agent

  # define the header section
  if !defined(Concat[$target]) {
    concat { $target:
      ensure => $ensure,
      owner  => 'root',
      group  => 'root',
      notify => Service[$datadog_agent::params::service_name],
    }

    concat::fragment { "${target}-header":
      target  => $target,
      content => "init_config:\n\ninstances:\n",
      order   => '00',
      notify  => Service[$datadog_agent::params::service_name],
    }
  }

  concat::fragment { $name:
    target  => $target,
    source  => $source,
    content => $content,
    notify  => Service[$datadog_agent::params::service_name],
  }
}
