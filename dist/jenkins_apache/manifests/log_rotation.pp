# run compress-log.rb periodically to compress old log files
class jenkins_apache::log_rotation {
  file { '/var/log/apache2/compress-log.rb':
    source  => "puppet:///modules/${::module_name}/compress-log.rb",
    mode    => '0700',
    require => Package['apache2'],
  }

  cron {
  'compress logs':
    ensure  => present,
    command => 'cd /var/log/apache2; ./compress-log.rb',
    user    => root,
    minute  => 7,
    require => File['/var/log/apache2/compress-log.rb'],
  }
}
