#!/usr/bin/perl
use DBI;
use DBD::mysql;
require('conf.pl');

#connect to db
my $dataSource = 'DBI:mysql:'.$db_name.':'. $db_hostname;
$db = DBI->connect( $dataSource,$username,$password) or die("Cannot connect to databse");

$db->do('CREATE DATABASE IF NOT EXISTS $db_name') or die("Cannot create the databse") ;

$db->do('USE $db_name');

$db->do('CREATE TABLE IF NOT EXISTS `host_services` (
					`ipaddress` varchar(128) NOT NULL,
  `oid` varchar(256) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
');

$db->do('CREATE TABLE IF NOT EXISTS `host_service_results` (
  `ipaddress` text NOT NULL,
  `oid` text NOT NULL,
  `timestamp` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `results` longtext NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
');
$db->do('CREATE TABLE IF NOT EXISTS `host_table` (
  `ipaddress` varchar(15) NOT NULL,
  `identifier` varchar(128) NOT NULL,
  `hostname` varchar(50) NOT NULL,
  `sys_description` text NOT NULL,
  `sys_uptime` bigint(10) unsigned NOT NULL,
  `no_of_inf` int(2) unsigned NOT NULL,
  `ip_forwarding` int(11) NOT NULL,
  `community_string` varchar(15) NOT NULL,
  PRIMARY KEY (`ipaddress`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;');
$db->do('CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(10) NOT NULL,
  `password` varchar(32) NOT NULL,
  `level` int(1) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`)
) ENGINE=InnoDB  DEFAULT CHARSET=latin1 AUTO_INCREMENT=2 ;');

$db->do('INSERT INTO `users` (`name`, `password`, `level`) VALUES (md5("admin"), md5("admin"), 1)');
$db->disconnect();
