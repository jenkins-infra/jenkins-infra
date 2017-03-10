# Deploy datadog resources on kubernetes cluster
class profile::kubernetes::resources::datadog (
    $apiKey = base64('encode', $::datadog_agent::api_key, 'strict')
  ){
  include ::stdlib
  include profile::kubernetes::params
  include profile::kubernetes::kubectl

  file { 'datadog_dir':
    ensure => 'directory',
    owner  => $profile::kubernetes::params::user,
    path   => "${profile::kubernetes::params::resources}/datadog",
  }

  file { 'datadog_secret':
    ensure  => 'present',
    content => template("${module_name}/kubernetes/resources/datadog/secret.yaml.erb"),
    path    => "${profile::kubernetes::params::resources}/datadog/secret.yaml",
    owner   => $profile::kubernetes::params::user,
  }

  file { 'datadog_daemonset':
    ensure  => 'present',
    content => template("${module_name}/kubernetes/resources/datadog/daemonset.yaml.erb"),
    path    => "${profile::kubernetes::params::resources}/datadog/daemonset.yaml",
    owner   => $profile::kubernetes::params::user,
  }

  $daemonset = loadyaml("${profile::kubernetes::params::resources}/datadog/daemonset.yaml")
  # Search app label value
  if ! empty($daemonset){
    $label_app = $daemonset['spec']['template'][metadata][labels][app]
  }

  exec { 'apply secret':
    command     => "kubectl apply -f ${profile::kubernetes::params::resources}/datadog/secret.yaml",
    path        => ["${profile::kubernetes::params::bin}/"],
    environment => ["KUBECONFIG=${profile::kubernetes::params::home}/.kube/config"] ,
    logoutput   => true,
  }

  exec { 'apply daemonset':
    command     => "kubectl apply -f ${profile::kubernetes::params::resources}/datadog/daemonset.yaml",
    path        => ["${profile::kubernetes::params::bin}/"],
    environment => ["KUBECONFIG=${profile::kubernetes::params::home}/.kube/config"] ,
    logoutput   => true,
  }

  # Only delete pods if secrets were udpated and daemonset already exist
  exec { 'reset daemonset pods':
    path        => ["${profile::kubernetes::params::bin}/"],
    command     => "kubectl delete pods -l app=${label_app}",
    refreshonly => true,
    environment => ["KUBECONFIG=${profile::kubernetes::params::home}/.kube/config"] ,
    logoutput   => true,
    onlyif      => 'kubectl get daemonset datadog',
    subscribe   => [
      File['datadog_secret'],
    ],
    before      => Exec['apply daemonset']
  }
}
