#
# Creates the auth endpoints for keystone
#
# == Parameters
#
# * public_address   - public address for keystone endpoint. Optional. Defaults to 127.0.0.1.
# * admin_address    - admin address for keystone endpoint. Optional. Defaults to 127.0.0.1.
# * internal_address - internal address for keystone endpoint. Optional. Defaults to 127.0.0.1.
# * public_port      - Port for non-admin access to keystone endpoint. Optional. Defaults to 5000.
# * admin_port       - Port for admin access to keystone endpoint. Optional. Defaults to 35357.
# * public_path      - Path portion of the url for public keystone endpoint. Optional. Defaults to '/'.
#                      see manifests/wsgi/apache.pp for more detail.
# * admin_path       - Path portion of the url for admin keystone endpoint. Optional. Defaults to '/'.
# * internal_path    - Path portion of the url for internal keystone endpoint. Optional. Defaults to $public_path.
# * region           - Region for endpoint. Optional. Defaults to RegionOne.
#
# == Sample Usage
#
#   class { 'keystone::endpoint':
#     :public_address   => '154.10.10.23',
#     :admin_address    => '10.0.0.7',
#     :internal_address => '11.0.1.7',
#   }
#
#
class keystone::endpoint(
  $public_address   = '127.0.0.1',
  $admin_address    = '127.0.0.1',
  $internal_address = '127.0.0.1',
  $public_port      = '5000',
  $admin_port       = '35357',
  $internal_port    = undef,
  $region           = 'RegionOne',
  $public_protocol  = 'http',
  $public_path      = '/',
  $admin_path       = '/',
  $internal_path    = undef
) {
  if $internal_port == undef {
    $internal_port_real = $public_port
  } else {
    $internal_port_real = $internal_port
  }

  if $internal_path == undef {
    $internal_path_real = $public_path
  } else {
    $internal_path_real = $internal_path
  }

  # Paths should start and end with a '/'
  validate_re($public_path, '^/(.+/)?$')
  validate_re($admin_path, '^/(.+/)?$')
  validate_re($internal_path_real, '^/(.+/)?$')

  keystone_service { 'keystone':
    ensure      => present,
    type        => 'identity',
    description => 'OpenStack Identity Service',
  }
  keystone_endpoint { "${region}/keystone":
    ensure       => present,
    public_url   => "${public_protocol}://${public_address}:${public_port}${public_path}v2.0",
    admin_url    => "http://${admin_address}:${admin_port}${admin_path}v2.0",
    internal_url => "http://${internal_address}:${internal_port_real}${internal_path_real}v2.0",
    region       => $region,
  }
}
