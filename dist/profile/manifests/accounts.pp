#
# Profile defining all the `account` resources with all our important account
# information
class profile::accounts {
  $accounts = lookup( {
      'name'  => 'accounts',
      'merge' => {
        'strategy' => 'deep',
      },
  })

  create_resources('account', $accounts)
}
