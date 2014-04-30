#
# Profile defining all the `account` resources with all our important account
# information
class profile::accounts {
  $accounts = hiera_hash('accounts')
  create_resources('account', $accounts)
}
