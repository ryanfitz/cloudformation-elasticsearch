class elasticsearch($version = "0.19.12") {
  $esBasename = "elasticsearch"
  $esName     = "${esBasename}-${version}"
  $esFile     = "${esName}.tar.gz"
  $esPath     = "/usr/local/${esName}"

  package{ 'java-1.7.0-openjdk':
    ensure => installed,
  }

  file { "$esPath":
    ensure     => directory,
    owner      => "root",
    group      => "root",
    recurse    => true
  }

  file { "/tmp/$esFile":
    source => "puppet:///modules/elasticsearch/$esFile",
    mode => 644,
    owner => "root",
    group => "root",
    require => File["$esPath"],
  }

  exec {"extract-elasticsearch":
    path => "/bin:/usr/bin",
    command => "tar -xzf /tmp/$esFile -C /tmp",
    require => File["/tmp/$esFile"],
    unless  => "test -f $esPath/bin/elasticsearch",
  }

  exec {"elasticsearch-package":
    path => "/bin:/usr/bin",
    command => "cp -rf /tmp/$esName/. $esPath/.",
    require => Exec["extract-elasticsearch"],
    unless  => "test -f $esPath/bin/elasticsearch",
    #notify => Service["$esBasename"],
  }

  exec {"clean-tmp-elasticsearch":
    path => "/bin:/usr/bin",
    command => "rm -rf /tmp/$esName.tar.gz",
    require => Exec["elasticsearch-package"],
  }

  file { "/etc/$esBasename":
    ensure => link,
    target => "$esPath/config",
    require => Exec["elasticsearch-package"],
  }

  file { "/etc/init/elasticsearch.conf":
    source => "puppet:///modules/elasticsearch/elasticsearch.conf",
    mode => 644,
    owner => "root",
    group => "root",
    require => Exec["elasticsearch-package"],
  }

  file { "$esPath/config/elasticsearch.yml":
    source => "puppet:///modules/elasticsearch/elasticsearch.yml",
    mode => 644,
    owner => "root",
    group => "root",
    require => Exec["elasticsearch-package"],
  }

  exec { "aws-cloud-plugin":
    path => "/bin:/usr/bin",
    command => "$esPath/bin/plugin -install elasticsearch/elasticsearch-cloud-aws/1.10.0 $esPath",
    require => Exec["elasticsearch-package"],
    unless  => "test -d $esPath/plugins/cloud-aws",
  }

  file { "/var/log/elasticsearch":
    ensure  => directory,
    mode    => 644,
    owner   => "root",
    group   => "root",
    recurse => true
  }

  file { [ "/media/p_iops_vol0/elasticsearch/", "/media/p_iops_vol0/elasticsearch/data"]:
    ensure => "directory",
    owner   => "root",
    group   => "root",
    mode    => 755,
  }

  service { "$esBasename":
    ensure => running,
    restart   => '/sbin/restart elasticsearch',
    start     => '/sbin/start elasticsearch',
    stop      => '/sbin/stop elasticsearch',
    status    => '/sbin/status elasticsearch',
    require => File["/etc/init/$esBasename.conf"],
  }

}

