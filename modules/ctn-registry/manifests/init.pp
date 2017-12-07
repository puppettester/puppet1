class ctn-registry {
	include ctn-registry::install
        include ctn-registry::certificates
	include ctn-registry::config
	include ctn-registry::container
}


class ctn-registry::install(
    $nfs_mount,
){

    exec {'create_folder':
      command => 'mkdir /home/registry && chown root:root /home/registry && chmod 750 /home/registry',
      unless      => 'test -d /home/registry',
      path         => '/usr/bin:/usr/sbin:/bin',
      before      => Mount["/home/registry"],
    }

    package { 'nfs-client':
        ensure => latest,
    }


    mount { '/home/registry':
        ensure => mounted,
        atboot => true,
        device => $nfs_mount,
        fstype => 'nfs',
        options => 'rw',
    }

    file { '/home/registry':
        ensure => directory,
	mode  => '755',
        require => Mount['/home/registry'],
    }
}

class ctn-registry::certificates (
    $private_key,
    $certificate,
){
    file { '/certs/':
        ensure => directory,
        owner => 'root',
        group => 'root',
        mode => '0740',
        require => Class['ctn-registry::install'],
    }

    file { '/certs/server.key':
        ensure => file,
        owner => 'root',
        group => 'root',
        mode => '0640',
        content => template('ctn-registry/server.key.erb'),
        require => File['/certs/'],
    }

    file { '/certs/server.crt':
        ensure => file,
        owner => 'root',
        group => 'root',
        mode => '0640',
        content => template('ctn-registry/server.crt.erb'),
        require => File['/certs/'],
    }
}

class ctn-registry::config(
    $port,
    $rootdirectory,
    $http_secret,
    $delete_enable,
    $redis_enable,
){
    file { '/etc/docker':
        ensure => directory,
        owner  => 'root',
        group  => 'root',
        mode   => '0740',
        require => Class['ctn-registry::certificates'],
    }

    file { '/etc/docker/registry':
        ensure  => directory,
        owner   => 'root',
        group   => 'root',
        mode    => '0740',
        require => File['/etc/docker'],
    }

    file { '/etc/docker/registry/config.yml':
        ensure  => file,
        owner   => 'root',
        group   => 'root',
        mode    => '0640',
        content => template('ctn-registry/config.yml.erb'),
        notify => Service['docker-ctn-registry'],
	require => File['/etc/docker/registry'],
    }    
}

class ctn-registry::container {
    docker::run { 'ctn-registry':
        image => "registry:2.5.0",
        net => 'host',
        volumes => [
            '/etc/docker/registry/config.yml:/etc/docker/registry/config.yml:ro',
            '/certs:/certs:ro',
            '/home/registry:/home/registry',
        ],
        restart_service => true,
        privileged => false,
        pull_on_start => false,
        require => Class['ctn-registry::config'],
    }
}

