#
# Class to serve keystone with apache mod_wsgi
#
# == Parameters
#
#   [servername] The servername for the virtualhost
#     defaults to $::fqdn
#   [base_url] The base url keystone will be served from
#     defaults to '/keystone'
#   [ssl] Set to true to enable SSL. Defaults to false
#   [ssl_only] Set to true to disable non-ssl. Defaults to false
#
# == Dependencies
#
#   requires Class['apache'] & Class['keystone']
#
# == Examples
#
#   include apache
#
#   class { 'keystone::wsgi::apache': }
#
# == Authors
#
#   François Charlier <francois.charlier@enovance.com>
#
# == Copyright
#
#   Copyright 2013 eNovance <licensing@enovance.com>
#
class keystone::wsgi::apache (
  $servername = $::fqdn,
  $base_url   = '/keystone',
  $ssl        = false,
  $ssl_only   = false,
) {

  include 'keystone::params'

#  Class['keystone'] -> Class['keystone::wsgi::apache']
#  Class['apache'] -> Class['keystone::wsgi::apache']

  file { $::keystone::params::keystone_wsgi_script_path:
    ensure  => directory,
    owner   => 'keystone',
    group   => 'keystone',
    require => Package['httpd'],
  }

  file { 'keystone_wsgi_admin':
    ensure  => file,
    path    => "${::keystone::params::keystone_wsgi_script_path}/admin",
    source  => $::keystone::params::keystone_wsgi_script_source,
    owner   => 'keystone',
    group   => 'keystone',
    mode    => '0644',
    require => File[$::keystone::params::keystone_wsgi_script_path],
  }

  file { 'keystone_wsgi_main':
    ensure  => file,
    path    => "${::keystone::params::keystone_wsgi_script_path}/main",
    source  => $::keystone::params::keystone_wsgi_script_source,
    owner   => 'keystone',
    group   => 'keystone',
    mode    => '0644',
    require => File[$::keystone::params::keystone_wsgi_script_path],
  }

  include 'apache::mod::wsgi'

  if ! $ssl_only {
    apache::vhost { 'keystone_wsgi':
      servername         => $servername,
      port               => 80,
      docroot            => $::keystone::params::keystone_wsgi_script_path,
      docroot_owner      => 'keystone',
      docroot_group      => 'keystone',
      configure_firewall => false,
      custom_fragment    => template('keystone/apache/keystone_wsgi.erb'),
      require            => Class['apache::mod::wsgi'],
    }
  }

  if $ssl {
    if $::osfamily == 'redhat' {
      include 'apache::mod::nss'
    }

    apache::vhost { 'keystone_wsgi_ssl':
      servername         => $servername,
      port               => 443,
      docroot            => $::keystone::params::keystone_wsgi_script_path,
      docroot_owner      => 'keystone',
      docroot_group      => 'keystone',
      configure_firewall => false,
      custom_fragment    => template('keystone/apache/keystone_wsgi_ssl.erb'),
      require            => Class['apache::mod::wsgi'],
    }
  }

  Keystone_config <| |> ~> Service['httpd']
}
