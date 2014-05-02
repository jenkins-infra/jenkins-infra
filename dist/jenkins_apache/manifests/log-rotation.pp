# run compress-log.rb periodically to compress old log files
class apache2::log-rotation {
  file { "/var/log/apache2/compress-log.rb":
    source  => "puppet:///modules/apache2/compress-log.rb",
    mode    => "700",
    require => Package['apache2'];
  }

  cron {
  "compress logs":
    command => "cd /var/log/apache2; ./compress-log.rb",
    user    => root,
    minute  => 7,
    ensure  => present,
    require => Package['apache2'];
  }
}
