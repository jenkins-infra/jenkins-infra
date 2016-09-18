#
# Profile defining all the `account` resources with all our important account
# information
class profile::accounts {
  group { 'atlassian-admins':
    ensure => present,
  }

  $accounts = lookup('accounts',
                      Hash,
                      {'strategy' => 'deep',
                      'merge_hash_arrays' => true})
  create_resources('account', $accounts)
}
