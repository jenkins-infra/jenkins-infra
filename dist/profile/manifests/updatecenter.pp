# Profile for managing the necessary pre-requisites for running the Update
# Center code
#
# Typically this host(s) will be acting as a Jenkins agent attached to a
# trusted CI environment
# TODO: requirement for $homedir/.m2 (same volume as agent workspace because of hardlinks)
#   + enough space because of Maven cache
class profile::updatecenter (
  Stdlib::Absolutepath $home_dir      = '/home/jenkins',
  String               $user          = 'jenkins',
  Optional[String]     $rsync_privkey = '',
  Optional[String]     $rsync_pubkey  = '',
) {
  include stdlib # Required to allow using stlib methods and custom datatypes

  if $rsync_privkey {
    $rsync_privkeyfile = "${home_dir}/.ssh/updates-rsync-key"

    file { $rsync_privkeyfile:
      ensure  => file,
      mode    => '0600',
      content => $rsync_privkey,
    }

    file { "${rsync_privkeyfile}.pub":
      ensure  => file,
      mode    => '0644',
      content => $rsync_pubkey,
    }

    concat::fragment { 'updates-rsync-key concat':
      target  => "${home_dir}/.ssh/config",
      order   => '99',
      content => "
Host updates.jenkins.io
  IdentityFile ${rsync_privkeyfile}
",
    }
  }

  ensure_resources('concat', {
      "${home_dir}/.ssh/config" => {
        ensure  => present,
        mode    => '0644',
        owner   => $user,
        group   => $user,
      },
    }
  )
}
