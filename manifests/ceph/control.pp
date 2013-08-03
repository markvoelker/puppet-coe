class coe::ceph::control(
  $glance_store_user = 'admin',
  $glance_store_pool = 'images',
  
) {

  include 'ceph::package'

  Package['ceph'] -> Ceph::Key <<| title == 'admin' |>>

  class { 'ceph::apt::ceph': release => $::ceph_release }

  package { 'ceph-common':
    ensure => present,
    require => Apt::Source['ceph'],
  }

  package { 'python-ceph':
    ensure => present,
    require => Apt::Source['ceph'],
  }
 
  class { 'ceph::conf':
    fsid      => $fsid,
    conf_owner => 'glance',
    conf_group => 'glance',
  }

  file { '/etc/ceph/client.admin':
    ensure => present,
    owner => 'cinder',
    group => 'cinder',
    mode  => '660',
    require => Exec['copy the admin key to make glance work'],
  }

  file { '/etc/ceph/keyring':
    owner => 'cinder',
    group => 'cinder',
    mode  => 0600,
  }
  
  exec { 'copy the admin key to make cinder work':
    command => 'cp /etc/ceph/keyring /etc/ceph/client.admin',
    creates => '/etc/ceph/client.admin',
    require => [ Package['ceph'], Ceph::Key['admin'] ],
  }

  exec { 'create the pool':
    command => "/usr/bin/ceph osd pool create ${glance_store_pool} 128",
    unless  => "/usr/bin/rados lspools | grep -sq ${glance_store_pool}",
    require => Exec['copy the admin key to make glance work'],
  }

}
