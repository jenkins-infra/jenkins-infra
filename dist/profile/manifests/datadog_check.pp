# Assemble fragments into datadog checker configuration files
#
define profile::datadog_check (
  String                           $ensure    = 'present',
  String                           $checker   = '',
  Optional[Variant[String, Array]] $source    = undef,
  Optional[Any]                    $content   = undef,
) {
  include stdlib # Required to allow using stlib methods and custom datatypes
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

  if $content {
    concat::fragment { $name:
      target  => $target,
      source  => $source,
      content => $content,
      notify  => Service[$datadog_agent::params::service_name],
    }
  }
}
