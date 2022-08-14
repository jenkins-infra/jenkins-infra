#
# Vagrant profile for capturing some of the spceifics we need for Vagrant boxes
# to pvoision cleanly
class profile::vagrant {
  Exec { '/usr/bin/apt-get update --quiet':
  }
  include sudo

  # Vagrant defines a default user `vagrant` which should have passwordless sudo permission
  sudo::conf { 'vagrant':
    ensure   => file,
    priority => '10',
    content  => 'vagrant ALL=(ALL) NOPASSWD: ALL',
  }

  ######
  # The following code block is a hack to ensure that LVM volumes are created without any errors in the Vagrant environment.
  # Challenge comes from LVM requiring `udev` to discover and manage devices. But udev is not working inside a docker container (other than sharing the host udev).
  # The trick is to run the custom lv commands and then delegate to the lvm the missing part
  # Main point is the "lvcreate" that should use the flag `--zero n` but the puppet module does not allow it alas.
  $default_extent_size_bytes = 4194304 # 4Mb

  lookup('lvm::volume_groups', undef, undef, {}).each | $vg_name, $vg_config| {
    # Create an array with the list of specified logicial volumes sizes in bytes
    # Ref. https://puppet.com/docs/puppet/6/function.html#reduce
    $lv_sizes_in_byte = $vg_config['logical_volumes'].reduce([]) |$memo, $value| {
      $memo + to_bytes($value[1]['size'])
    }

    # Calculate the sum of all these sizes from the array
    $total_lv_size_in_bytes = $lv_sizes_in_byte.reduce(0) |$memo, $value| {
      if ( $value % $default_extent_size_bytes > 0) {
        # Need to round up to the next extent
        $memo + $value + $default_extent_size_bytes - ($value % $default_extent_size_bytes)
      } else {
        $memo + $value
      }
    }
    notice("== Found a specified total of ${total_lv_size_in_bytes} bytes required for all LVM logical volumes")

    # How much PV to create ?
    $pv_count = $vg_config['physical_volumes'].size

    # Size per PV.

    $pv_size_in_megabyte = (($total_lv_size_in_bytes / $pv_count + $default_extent_size_bytes) / 1024 / 1024)
    notice("== Calculated a size of ${pv_size_in_megabyte} megabytes per LVM physical volumes")

    $vg_config['physical_volumes'].each | $index, $loopback_device| {
      # Store dummy device on root: NOT in /tmp, not in /dev (because these are tmpfs in containers)
      $dummy_device = "/dummy${index}"

      exec { "create ${dummy_device}":
        command => "dd if=/dev/zero of=${dummy_device} bs=1M count=${pv_size_in_megabyte}",
        unless  => "test -f ${dummy_device}",
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
      }

      $dmsetup_remove_cmd = 'dmsetup ls | awk \'{print $1}\' | xargs -I{} dmsetup remove {}'

      exec { "setup ${dummy_device} dummy device to ${loopback_device} loop device":
        # dmsetup is used to "force" remove the loopback
        command => "${dmsetup_remove_cmd} || true && losetup --detach-all && losetup --partscan ${loopback_device} ${dummy_device}",
        unless  => "losetup --associated ${dummy_device} | grep '${loopback_device}'",
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        require => Exec["create ${dummy_device}"],
      }

      # The lvm puppet module does not provide a 'disable zeroing' feature that would avoid requiring udev in the vagrant docker-container
      exec { "setup ${loopback_device} as a physical volume":
        command => "pvcreate ${loopback_device}",
        unless  => "pvscan | grep ${loopback_device}",
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        require => Exec["setup ${dummy_device} dummy device to ${loopback_device} loop device"],
        before  => Exec["setup volume group ${vg_name}"],
      }
    }

    # Create Volume Group
    $pv_list = join($vg_config['physical_volumes'], ' ')
    exec { "setup volume group ${vg_name}":
      command => "vgcreate ${vg_name} ${pv_list}",
      unless  => "vgscan | grep ${vg_name}",
      path    => '/usr/bin:/usr/sbin:/bin:/sbin',
      notify  => Exec['ensure vg nodes are created'],
    }

    # Create Logical Volumes
    $vg_config['logical_volumes'].each | $lv_name, $lv_config| {
      $lv_size_in_bytes = to_bytes($lv_config['size'])
      $new_lv_size_in_bytes = floor($lv_size_in_bytes / $default_extent_size_bytes) * $default_extent_size_bytes
      $new_lvsize =  $new_lv_size_in_bytes / 1024 / 1024
      $lv_create_cmd = "lvcreate --name ${lv_name} --size ${$new_lvsize} --zero n data"

      exec { "setup logical volume ${lv_name}":
        # Note the `--zero n` flag: it disable zeroing blocks to avoid requiring udev (nifty part)
        command => $lv_create_cmd,
        unless  => "lvscan | grep ${lv_name}",
        path    => '/usr/bin:/usr/sbin:/bin:/sbin',
        require => Exec["setup volume group ${vg_name}"],
        before  => Exec['ensure vg nodes are created'],
      }
    }

    # To avoid the mkfs errors 'The file <whatever> does not exist and no size was specified'
    exec { 'ensure vg nodes are created':
      command => 'vgscan --mknodes',
      path    => '/usr/bin:/usr/sbin:/bin:/sbin',
    }
  }
  ###### End custom hack LVM for Docker
}
