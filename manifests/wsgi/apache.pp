#
# Class to serve keystone with apache mod_wsgi
#
# Serving keystone from apache is the recommended way to go for production
# systems as the current keystone implementation is not multi-processor aware,
# thus limiting the performance for concurrent accesses.
#
# See the following URIs for reference:
#    https://etherpad.openstack.org/havana-keystone-performance
#    http://adam.younglogic.com/2012/03/keystone-should-move-to-apache-httpd/
#
# When using this class you should change your keystone endpoints and
# auth_token configuration:
#
# * Declare your keystone endpoints with:
#   - (public|admin|internal)_address matching $servername
#   - the correct ports (80 / 443)
#   - the correct protocol (http / https)
#   - the correct values for public_path & admin_path. if using this class'
#     default values, you should use respectively '/keystone/main/' and
#     '/keystone/admin/' (with trailing '/')
#
# * For modules using the 'auth_token' middleware, you'll have to use the
#   auth_admin_prefix parameter. Example for nova::api:
#
#     class { nova::api:
#       …
#       auth_host         => <same as $servername>,
#       auth_port         => <same as $port or $ssl_port>,
#       auth_protocol     => <https if using ssl, http else>,
#       auth_admin_prefix => <$base_url + '/admin'>, # eg: /keystone/admin
#       …
#     }
#
#  An example for endpoints declaration can be found in 'examples/apache.pp'
#
# == Parameters
#
#   [servername] The servername for the virtualhost
#     defaults to $::fqdn
#   [base_url] The base url keystone will be served from
#     defaults to '/keystone'
#   [port] The port to bind to
#   [ssl] Set to true to enable SSL. Defaults to false
#   [ssl_only] Set to true to disable non-ssl. Defaults to false
#   [ssl_port] The ssl port to bind to
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
  $port       = 80,
  $ssl        = false,
  $ssl_only   = false,
  $ssl_port   = 443,
) {

  include 'keystone::params'
  include 'apache'
  include 'apache::mod::wsgi'

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

  if ! $ssl_only {
    apache::vhost { 'keystone_wsgi':
      servername         => $servername,
      port               => $port,
      docroot            => $::keystone::params::keystone_wsgi_script_path,
      docroot_owner      => 'keystone',
      docroot_group      => 'keystone',
      configure_firewall => false,
      custom_fragment    => template('keystone/apache/keystone_wsgi.erb'),
      require            => Class['apache::mod::wsgi'],
    }
  }

  if $ssl or $ssl_only {
    apache::vhost { 'keystone_wsgi_ssl':
      servername         => $servername,
      port               => $ssl_port,
      ssl                => true,
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
