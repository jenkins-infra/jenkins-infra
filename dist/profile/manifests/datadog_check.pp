# Assemble fragments into datadog checker configuration files
#
define profile::datadog_check(
  $ensure    = present,
  $checker   = undef,
  $source    = undef,
  $content   = undef,
) {
  $target ="${datadog_agent::params::conf6_dir}/${checker}.yaml"

  include datadog_agent

  # define the header section
  if !defined(Concat[$target]) {
    concat { $target:
      owner => 'root',
      group => 'root',
    }

    concat::fragment { "${target}-header":
      target  => $target,
      content => "init_config:\n\ninstances:\n",
      order   => '00',
    }

    # when the file in question is updated, we need to restart datadog agent
    Exec["concat_${target}"] ~> Service[$datadog_agent::params::service_name]
  }

  concat::fragment { $name:
    ensure  => $ensure,
    target  => $target,
    source  => $source,
    content => $content,
  }
}
