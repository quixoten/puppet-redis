# == Function: redis::server
#
# Function to configure an redis server.
#
# === Parameters
#
# [*redis_name*]
#   Name of Redis instance. Default: call name of the function.
# [*redis_memory*]
#   Sets amount of memory used. eg. 100mb or 4g.
# [*redis_ip*]
#   Listen IP. Default: 127.0.0.1
# [*redis_port*]
#   Listen port of Redis. Default: 6379
# [*redis_usesocket*]
#   To enable unixsocket options. Default: false
# [*redis_socket*]
#   Unix socket to use. Default: /tmp/redis.sock
# [*redis_socketperm*]
#   Permission of socket file. Default: 755
# [*redis_mempolicy*]
#   Algorithm used to manage keys. See Redis docs for possible values. Default: allkeys-lru
# [*redis_memsamples*]
#   Number of samples to use for LRU policies. Default: 3
# [*redis_timeout*]
#   Default: 0
# [*redis_nr_dbs*]
#   Number of databases provided by redis. Default: 1
# [*redis_dbfilename*]
#   Name of database dump file. Default: dump.rdb
# [*redis_dir*]
#   Path for persistent data. Path is <redis_dir>/redis_<redis_name>/. Default: /var/lib
# [*redis_log_dir*]
#   Path for log. Full log path is <redis_log_dir>/redis_<redis_name>.log. Default: /var/log
# [*redis_loglevel*]
#   Loglevel of Redis. Default: notice
# [*notify_keyspace_events*]
#   Select which keyspace events to enable notifications for. Default: ""
# [*running*]
#   Configure if Redis should be running or not. Default: true
# [*enabled*]
#   Configure if Redis is started at boot. Default: true
# [*requirepass*]
#   Configure Redis AUTH password
# [*maxclients*]
#   Configure Redis maximum clients
# [*appendfsync_on_rewrite*]
#   Configure the no-appendfsync-on-rewrite variable.
#   Set to yes to enable the option. Defaults off. Default: false
# [*aof_rewrite_percentage*]
#   Configure the percentage size difference between the last aof filesize
#   and the newest to trigger a rewrite. Default: 100
# [*aof_rewrite_minsize*]
#   Configure the minimum size in mb of the aof file to trigger size
#   comparisons for rewriting.
#   Default: 64 (integer)
# [*redis_enabled_append_file*]
#   Enable custom append file. Default: false
# [*redis_append_file*]
#   Define the path for the append file. Optional. Default: undef
# [*redis_append_enable*]
#   Enable or disable the appendonly file option. Default: false
# [*slaveof*]
#   Configure Redis Master on a slave
# [*masterauth*]
#   Password used when connecting to a master server which requires authentication.
# [*slave_server_stale_data*]
#   Configure Redis slave to server stale data
# [*stop_writes_on_bgsave_error*]
#   Fail hard when the hard drive fails and RDB snapshots are enabled.
#   Default: true
# [*slave_read_only*]
#   Configure Redis slave to be in read-only mode
# [*repl_timeout*]
#   Configure Redis slave replication timeout
# [*repl_ping_slave_period*]
#   Configure Redis replication ping slave period
# [*save*]
#   Configure Redis save snapshotting. Example: [[900, 1], [300, 10]]. Default: []
# [*tcp_keepalive*]
#   If non-zero, use SO_KEEPALIVE to send TCP ACKs to clients in absence of
#   communication. Default: 0
# [*hash_max_ziplist_entries*]
#   Threshold for ziplist entries. Default: 512
# [*hash_max_ziplist_value*]
#   Threshold for ziplist value. Default: 64
#
# [*redis_run_dir*]
#
#   Default: `/var/run/redis`
#
#   Since redis automatically rewrite their config since version 2.8 what conflicts with puppet
#   the config files created by puppet will be copied to this directory and redis will be started from
#   this copy.
#
# [*manage_logrotate*]
#   Configure logrotate rules for redis server. Default: true
define redis::server (
  $aof_rewrite_minsize         = 64,
  $aof_rewrite_percentage      = 100,
  $appendfsync_on_rewrite      = false,
  $enabled                     = true,
  $force_rewrite               = false,
  $hash_max_ziplist_entries    = 512,
  $hash_max_ziplist_value      = 64,
  $manage_logrotate            = true,
  $masterauth                  = undef,
  $maxclients                  = undef,
  $notify_keyspace_events      = '',
  $redis_appedfsync            = 'everysec',
  $redis_append_enable         = false,
  $redis_append_file           = undef,
  $redis_appendfsync           = 'everysec',
  $redis_dbfilename            = 'dump.rdb',
  $redis_dir                   = '/var/lib',
  $redis_enabled_append_file   = false,
  $redis_ip                    = '127.0.0.1',
  $redis_log_dir               = '/var/log',
  $redis_loglevel              = 'notice',
  $redis_memory                = '100mb',
  $redis_mempolicy             = 'allkeys-lru',
  $redis_memsamples            = 3,
  $redis_name                  = $name,
  $redis_nr_dbs                = 1,
  $redis_pid_dir               = '/var/run',
  $redis_port                  = 6379,
  $redis_run_dir               = '/var/run/redis',
  $redis_socket                = '/tmp/redis.sock',
  $redis_socketperm            = 755,
  $redis_timeout               = 0,
  $redis_usesocket             = false,
  $repl_ping_slave_period      = 10,
  $repl_timeout                = 60,
  $requirepass                 = undef,
  $running                     = true,
  $save                        = [],
  $slave_read_only             = true,
  $slave_serve_stale_data      = true,
  $slaveof                     = undef,
  $stop_writes_on_bgsave_error = true,
  $tcp_keepalive               = 0,
) {
  $redis_user              = $::redis::install::redis_user
  $redis_group             = $::redis::install::redis_group

  $redis_install_dir = $::redis::install::redis_install_dir
  $redis_init_script = $::operatingsystem ? {
    /(Debian|Ubuntu)/                                          => 'redis/etc/init.d/debian_redis-server.erb',
    /(Fedora|RedHat|CentOS|OEL|OracleLinux|Amazon|Scientific)/ => 'redis/etc/init.d/redhat_redis-server.erb',
    /(SLES)/                                                   => 'redis/etc/init.d/sles_redis-server.erb',
    /(Gentoo)/                                                 => 'redis/etc/init.d/gentoo_redis-server.erb',
    default                                                    => undef,
  }
  $redis_2_6_or_greater = versioncmp($::redis::install::redis_version,'2.6') >= 0

  # redis conf file
  $conf_file_name = "redis_${redis_name}.conf"
  $conf_file = "/etc/${conf_file_name}"
  file { $conf_file:
      ensure  => file,
      content => template('redis/etc/redis.conf.erb'),
      require => Class['redis::install'];
  }

  # startup script
  if ($::osfamily == 'RedHat' and versioncmp($::operatingsystemmajrelease, '7') >=0) {
    $service_file = "/usr/lib/systemd/system/redis-server_${redis_name}.service"
    exec { "systemd_service_${redis_name}_preset":
      command     => "/bin/systemctl preset redis-server_${redis_name}.service",
      notify      => Service["redis-server_${redis_name}"],
      refreshonly => true,
    }

    file { $service_file:
      ensure  => file,
      mode    => '0644',
      content => template('redis/systemd/redis.service.erb'),
      require => [
        File[$conf_file],
        File["${redis_dir}/redis_${redis_name}"]
      ],
    }
  } else {
    $service_file = "/etc/init.d/redis-server_${redis_name}"
    file { $service_file:
      ensure  => file,
      mode    => '0755',
      content => template($redis_init_script),
      require => [
        File[$conf_file],
        File["${redis_dir}/redis_${redis_name}"]
      ],
    }
  }

  # path for persistent data
  # If we specify a directory that's not default we need to pass it as hash
  # and ensure that we do not have duplicate warning, when we have multiple
  # redis Instances on one host
  if ! defined(File[$redis_dir]) {
    file { $redis_dir:
      ensure  => directory,
      require => Class['redis::install'],
    }
  }

  file { "${redis_dir}/redis_${redis_name}":
    ensure  => directory,
    require => Class['redis::install'],
    owner   => $redis_user,
    group   => $redis_group,
  }

  if ($manage_logrotate == true){
    # install and configure logrotate
    if ! defined(Package['logrotate']) {
      package { 'logrotate': ensure => installed; }
    }

    file { "/etc/logrotate.d/redis-server_${redis_name}":
      ensure  => file,
      content => template('redis/redis_logrotate.conf.erb'),
      require => [
        Package['logrotate'],
        File[$conf_file],
      ]
    }
  }

  # manage redis service
  service { "redis-server_${redis_name}":
    ensure     => $running,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => File[$service_file],
    subscribe  => File[$conf_file],
  }
}
