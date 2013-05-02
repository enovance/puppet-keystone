require 'spec_helper'

describe 'keystone::wsgi::apache' do

  let :facts do
    {
      :processorcount => 42,
      :concat_basedir => '/var/lib/puppet/concat',
      :fqdn           => 'some.host.tld'
    }
  end

  let :pre_condition do
    'include apache'
  end

  describe 'on RedHat platforms' do
    before do
      facts.merge!({
        :osfamily               => 'RedHat',
        :operatingsystemrelease => '6.0'
      })
    end

    it { should contain_service('httpd').with_name('httpd') }

    describe 'when enabling ssl' do
      let :params do
        { :ssl => true }
      end

      it { should contain_apache__vhost('keystone_wsgi_ssl').with(
        'servername'         => 'some.host.tld',
        'port'               => '443',
        'ssl'                => 'true',
        'docroot'            => '/usr/lib/cgi-bin/keystone',
        'docroot_owner'      => 'keystone',
        'docroot_group'      => 'keystone',
        'configure_firewall' => 'false',
        'custom_fragment'    => <<EOF,
WSGIScriptAlias /keystone/main  /usr/lib/cgi-bin/keystone/main
WSGIScriptAlias /keystone/admin  /usr/lib/cgi-bin/keystone/admin

WSGIDaemonProcess keystone user=keystone group=keystone processes=42 threads=1
WSGIProcessGroup keystone
EOF
        'require'            => 'Class[Apache::Mod::Wsgi]'
      )}

      describe 'when enabling ssl_only' do
        before do
          params.merge!({ :ssl_only => true })
        end

        it { should contain_apache__vhost('keystone_wsgi_ssl').with(
          'servername'         => 'some.host.tld',
          'port'               => '443',
          'ssl'                => 'true',
          'docroot'            => '/usr/lib/cgi-bin/keystone',
          'docroot_owner'      => 'keystone',
          'docroot_group'      => 'keystone',
          'configure_firewall' => 'false',
          'custom_fragment'    => <<EOF,
WSGIScriptAlias /keystone/main  /usr/lib/cgi-bin/keystone/main
WSGIScriptAlias /keystone/admin  /usr/lib/cgi-bin/keystone/admin

WSGIDaemonProcess keystone user=keystone group=keystone processes=42 threads=1
WSGIProcessGroup keystone

<Location "/keystone">
  NSSRequireSSL
</Location>
EOF
          'require'            => 'Class[Apache::Mod::Wsgi]'
        )}

        it { should_not contain_apache__vhost('keystone_wsgi') }
      end
    end
  end

  describe 'on Debian platforms' do
    before do
      facts.merge!({
        :osfamily               => 'Debian',
        :operatingsystemrelease => '7.0'
      })
    end

    it { should contain_service('httpd').with_name('apache2') }

    describe 'with default parameters' do

      it { should contain_class('keystone::params') }
      it { should contain_class('apache') }
      it { should contain_class('apache::mod::wsgi') }

      it { should contain_file('/usr/lib/cgi-bin/keystone').with(
        'ensure'  => 'directory',
        'owner'   => 'keystone',
        'group'   => 'keystone',
        'require' => 'Package[httpd]'
      )}

      it { should contain_file('keystone_wsgi_admin').with(
        'ensure'  => 'file',
        'path'    => '/usr/lib/cgi-bin/keystone/admin',
        'source'  => 'puppet:///modules/keystone/httpd/keystone.py',
        'owner'   => 'keystone',
        'group'   => 'keystone',
        'mode'    => '0644',
        'require' => 'File[/usr/lib/cgi-bin/keystone]'
      )}

      it { should contain_file('keystone_wsgi_main').with(
        'ensure' => 'file',
        'path'    => '/usr/lib/cgi-bin/keystone/main',
        'source'  => 'puppet:///modules/keystone/httpd/keystone.py',
        'owner'   => 'keystone',
        'group'   => 'keystone',
        'mode'    => '0644',
        'require' => 'File[/usr/lib/cgi-bin/keystone]'
      )}


      it { should contain_apache__vhost('keystone_wsgi').with(
        'servername'         => 'some.host.tld',
        'port'               => '80',
        'docroot'            => '/usr/lib/cgi-bin/keystone',
        'docroot_owner'      => 'keystone',
        'docroot_group'      => 'keystone',
        'configure_firewall' => 'false',
        'custom_fragment'    => <<EOF,
WSGIScriptAlias /keystone/main  /usr/lib/cgi-bin/keystone/main
WSGIScriptAlias /keystone/admin  /usr/lib/cgi-bin/keystone/admin

WSGIDaemonProcess keystone user=keystone group=keystone processes=42 threads=1
WSGIProcessGroup keystone
EOF
        'require'            => 'Class[Apache::Mod::Wsgi]'
      )}

      describe 'when enabling ssl' do
        let :params do
          { :ssl => true }
        end

        it { should contain_apache__vhost('keystone_wsgi_ssl').with(
          'servername'         => 'some.host.tld',
          'port'               => '443',
          'ssl'                => 'true',
          'docroot'            => '/usr/lib/cgi-bin/keystone',
          'docroot_owner'      => 'keystone',
          'docroot_group'      => 'keystone',
          'configure_firewall' => 'false',
          'custom_fragment'    => <<EOF,
WSGIScriptAlias /keystone/main  /usr/lib/cgi-bin/keystone/main
WSGIScriptAlias /keystone/admin  /usr/lib/cgi-bin/keystone/admin

WSGIDaemonProcess keystone user=keystone group=keystone processes=42 threads=1
WSGIProcessGroup keystone
EOF
        'require'            => 'Class[Apache::Mod::Wsgi]'
        )}


        describe 'when enabling ssl_only' do
          before do
            params.merge!({ :ssl_only => true })
          end

          it { should contain_apache__vhost('keystone_wsgi_ssl').with(
            'servername'         => 'some.host.tld',
            'port'               => '443',
            'ssl'                => 'true',
            'docroot'            => '/usr/lib/cgi-bin/keystone',
            'docroot_owner'      => 'keystone',
            'docroot_group'      => 'keystone',
            'configure_firewall' => 'false',
            'custom_fragment'    => <<EOF,
WSGIScriptAlias /keystone/main  /usr/lib/cgi-bin/keystone/main
WSGIScriptAlias /keystone/admin  /usr/lib/cgi-bin/keystone/admin

WSGIDaemonProcess keystone user=keystone group=keystone processes=42 threads=1
WSGIProcessGroup keystone

<Location "/keystone">
  SSLRequireSSL
</Location>
EOF
            'require'            => 'Class[Apache::Mod::Wsgi]'
          )}

          it { should_not contain_apache__vhost('keystone_wsgi') }
        end

      end

    end

    describe 'with overriden parameters' do
      let :params do
        {
          :servername => 'dummy.host.tld',
          :base_url   => '/openstack_identity',
          :port       => 8000,
          :ssl_port   => 8443,
        }
      end

      it { should contain_apache__vhost('keystone_wsgi').with(
        'servername'         => 'dummy.host.tld',
        'port'               => '8000',
        'docroot'            => '/usr/lib/cgi-bin/keystone',
        'docroot_owner'      => 'keystone',
        'docroot_group'      => 'keystone',
        'configure_firewall' => 'false',
        'custom_fragment'    => <<EOF,
WSGIScriptAlias /openstack_identity/main  /usr/lib/cgi-bin/keystone/main
WSGIScriptAlias /openstack_identity/admin  /usr/lib/cgi-bin/keystone/admin

WSGIDaemonProcess keystone user=keystone group=keystone processes=42 threads=1
WSGIProcessGroup keystone
EOF
        'require'            => 'Class[Apache::Mod::Wsgi]'
      )}

      describe 'when enabling ssl' do
        before do
          params.merge!({ :ssl => true })
        end

        it { should contain_apache__vhost('keystone_wsgi_ssl').with(
          'servername'         => 'dummy.host.tld',
          'port'               => '8443',
          'ssl'                => 'true',
          'docroot'            => '/usr/lib/cgi-bin/keystone',
          'docroot_owner'      => 'keystone',
          'docroot_group'      => 'keystone',
          'configure_firewall' => 'false',
          'custom_fragment'    => <<EOF,
WSGIScriptAlias /openstack_identity/main  /usr/lib/cgi-bin/keystone/main
WSGIScriptAlias /openstack_identity/admin  /usr/lib/cgi-bin/keystone/admin

WSGIDaemonProcess keystone user=keystone group=keystone processes=42 threads=1
WSGIProcessGroup keystone
EOF
        'require'            => 'Class[Apache::Mod::Wsgi]'
        )}

      end

    end

  end

end
