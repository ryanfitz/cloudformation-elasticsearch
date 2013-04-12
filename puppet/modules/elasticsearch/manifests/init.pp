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

  file { '/tmp/$esFile':
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
    notify => Service["$esBasename"],
  }

  exec {"clean-tmp-elasticsearch":
    path => "/bin:/usr/bin",
    command => "rm -rf /tmp/$esName.tar.gz",
    require => Exec["elasticsearch-package"],
  }

}
