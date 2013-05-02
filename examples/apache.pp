
Exec { logoutput => 'on_failure' }

package { 'curl': ensure => present }

class { 'mysql::server': }
class { 'keystone::db::mysql':
  password => 'keystone',
}
class { 'keystone':
  verbose        => true,
  debug          => true,
  sql_connection => 'mysql://keystone_admin:keystone@127.0.0.1/keystone',
  catalog_type   => 'sql',
  admin_token    => 'admin_token',
}
class { 'keystone::roles::admin':
  email    => 'test@puppetlabs.com',
  password => 'ChangeMe',
}
class { 'keystone::endpoint':
  public_address   => $::fqdn,
  admin_address    => $::fqdn,
  internal_address => $::fqdn,
  public_port      => 80,
  admin_port       => 80,
  public_protocol  => 'http',
  public_path      => '/keystone/main/',
  admin_path       => '/keystone/admin/',
}

# Very important, you won't be able to authenticate else !
keystone_config { 'token/driver': value => 'keystone.token.backends.sql.Token' }
include 'apache'
class { 'keystone::wsgi::apache': }
