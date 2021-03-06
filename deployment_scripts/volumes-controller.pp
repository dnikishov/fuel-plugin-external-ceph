$plugin_name = 'external-ceph'

notice("MODULAR: ${plugin_name}/volumes-controller.pp")


$external_ceph = hiera_hash('external-ceph', {})

$cinder_ceph        = pick($external_ceph['cinder_ceph'], false)
$cinder_user        = pick($external_ceph['cinder_user'], false)
$cinder_key         = pick($external_ceph['cinder_key'], false)
$cinder_pool        = pick($external_ceph['cinder_pool'], false)

$cinder_backup_pool = pick($external_ceph['cinder_backup_pool'], false)
$cinder_backup_user = pick($external_ceph['cinder_backup_user'], false)


include cinder::params


package { 'cinder':
  ensure  => installed,
  name    => $::cinder::params::package_name,
}

service { "${cinder::params::api_service}":
  enable => true,
  ensure => running,
}

package { "$::cinder::params::tgt_package_name":
  ensure   => installed,
  name     => $::cinder::params::tgt_package_name,
  before   => Class['cinder::volume'],
}

package { 'ceph-client-package':
  ensure => installed,
  name   => 'ceph',
}


service { "$::cinder::params::tgt_service_name":
  enable   => true,
  ensure   => running,
}

class { 'cinder::volume':
  enabled => true,
}

cinder_config {
  'DEFAULT/enabled_backends': value => 'external-ceph';
}

cinder::backend::rbd { 'external-ceph':
  rbd_user            => $cinder_user,
  rbd_pool            => $cinder_pool,
  rbd_secret_uuid     => 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455', # seems to be hardcoded in the library
}

#class { 'cinder::volume::rbd':
#  rbd_user            => $cinder_user,
#  rbd_pool            => $cinder_pool,
#  rbd_secret_uuid     => 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455', # seems to be hardcoded in the library
#}

class { 'cinder::backup':
  enabled => true,
}

class { 'cinder::backup::ceph':
  backup_ceph_user => $cinder_backup_user,
  backup_ceph_pool => $cinder_backup_pool,
}


Package['ceph-client-package'] -> Cinder_config<||>
Cinder_config<||> ~> Service["${cinder::params::api_service}"]
Cinder_config<||> ~> Service["${cinder::params::volume_service}"]
