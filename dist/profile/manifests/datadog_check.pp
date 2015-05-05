# Assemble fragments into datadog checker configuration files
#
define profile::datadog_check(
  $checker,
  $source    = undef,
  $content   = undef,
) {
  $target ="${datadog_agent::params::conf_dir}/${checker}.yaml"

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
  }

  concat::fragment { $name:
    target  => $target,
    source  => $source,
    content => $content,
  }
}