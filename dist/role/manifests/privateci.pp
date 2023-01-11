#
# A Jenkins Controller running in a private network
class role::privateci {
  include role::jenkins::controller

  $ci_fqdn = lookup('profile::jenkinscontroller::ci_fqdn')

  # Specify static SSL certs, expected to be managed by Let's Encrypt but manually (DNS)
  # ref. https://github.com/jenkins-infra/helpdesk/issues/3328
  Apache::Vhost <| title == $ci_fqdn |> {
    ssl_key       => "/etc/letsencrypt/live/${ci_fqdn}/privkey.pem",
    ssl_cert      => "/etc/letsencrypt/live/${ci_fqdn}/fullchain.pem",
  }
}
