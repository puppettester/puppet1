class ctn-docker {
    include ctn-docker::apthttps
    include ctn-docker::overlay
    include ctn-docker::home
    include ctn-docker::install
}

class ctn-docker::overlay {
    file { '/etc/modules-load.d/docker.conf':
        ensure => present,
        owner => 'root',
        group => 'root',
        mode => '0644',
        source =>
        'puppet:///modules/ctn-docker/modules-load.d/docker.conf',
    }
}

class ctn-docker::home {
    file { '/home/docker':
        ensure  =>  directory,
        owner   =>  root,
        group   =>  root,
        mode    =>  0701,
    }

    file { '/var/lib/docker':
        ensure  => link,
        target  => "/home/docker",
        force   => true,
        require => File['/home/docker'],
    }
}

# 'apt-transport-https' package is needed to refresh the apt repository, observed OVH Debian 8 default image doesn't have this package and apt-updates are failing as a result
# install_options of '--allow-unauthenticated', '-f' added as apt-transport-https depends on libcurl3-gnutls which couldn't be authenticated
class ctn-docker::apthttps {
	package { 'apt-transport-https':
		name => 'apt-transport-https',
		ensure => installed,
		install_options => ['--allow-unauthenticated', '-f'],
	}
}

class ctn-docker::install {
    class { 'docker':

        case $::fqdn {
            /\agent\/: {
              $version = hiera('ctn-docker::install::admin_host::version')
            }
            default: {
              $version = hiera('ctn-docker::install::version')
            }
        }

        version                     => $version,
        iptables                    => false,
        storage_driver              => 'overlay2',
        log_driver                  => 'journald',
	      require 		    => Class['ctn-docker::apthttps', 'ctn-docker::home', 'ctn-docker::overlay'],
    }
}
