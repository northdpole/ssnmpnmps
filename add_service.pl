#!/usr/bin/perl
use Net::IP;
use Net::Ping;
use Net::SNMP;
use DBI;
use DBD::mysql;
use Data::Dumper;
require('conf.pl');
use POSIX;
#defaults to make Aris' life easier
#found them here http://www.debianadmin.com/linux-snmp-oids-for-cpumemory-and-disk-statistics.html

@defaults = ('.1.3.6.1.4.1.2021.10.1.3.1',
						 '.1.3.6.1.4.1.2021.10.1.3.2',
						 '.1.3.6.1.4.1.2021.10.1.3.3',
						 '.1.3.6.1.4.1.2021.11.9.0',
						 '.1.3.6.1.4.1.2021.11.50.0',
						 '.1.3.6.1.4.1.2021.11.10.0',
						 '.1.3.6.1.4.1.2021.11.52.0',
						 '.1.3.6.1.4.1.2021.11.11.0',
						 '.1.3.6.1.4.1.2021.11.53.0',
						 '.1.3.6.1.4.1.2021.11.51.0',
						 '.1.3.6.1.4.1.2021.4.3.0',
						 '.1.3.6.1.4.1.2021.4.4.0',
						 '.1.3.6.1.4.1.2021.4.5.0',
						 '.1.3.6.1.4.1.2021.4.6.0',
						 '.1.3.6.1.4.1.2021.4.11.0',
						 '.1.3.6.1.4.1.2021.4.13.0',
						 '.1.3.6.1.4.1.2021.4.14.0',
						 '.1.3.6.1.4.1.2021.4.15.0',
						 '.1.3.6.1.4.1.2021.9.1.2.1',
						 '.1.3.6.1.4.1.2021.9.1.3.1',
						 '.1.3.6.1.4.1.2021.9.1.6.1',
						 '.1.3.6.1.4.1.2021.9.1.7.1',
						 '.1.3.6.1.4.1.2021.9.1.8.1',
						 '.1.3.6.1.4.1.2021.9.1.9.1',
						 '.1.3.6.1.4.1.2021.9.1.10.1',
						 '.1.3.6.1.2.1.1.3.0');

#Check for the right args
if(!defined $ARGV[0] ||($ARGV[0] eq '-h' || $ARGV[0] eq '--help')){
	print 'usage: perl add_service.pl $hostip ($community $OID) <-- optional
e.g.
perl add_service.pl 192.168.1.23  public 1.3.6.1.2.1.2.1.0 or
perl add_service.pl 192.168.1.23  public or using a net mask
perl add_service.pl 192.168.1.23/23  public 1.3.6.1.2.1.2.1.0 for a multitude of computers
if you wont provide a community id and an OID the defaults will be used.
default community is public, for a default list of oids read this file (lines 13 - 38)
for help use -h or --help
';
	exit;
}

if(defined $ARGV[0]){
	$ipaddress = $ARGV[0];
}else{
	die "\n please give an ip";
}
if(defined $ARGV[1]){
	$community = $ARGV[1];
}else{
	$community = 'pulic';
}
if(defined $ARGV[2]){
	$oid = $ARGV[2];
}else{
	$oid = 'default';
}

#Check if ip is a real ip and if its accessible
	$ip = new Net::IP($ipaddress) or die "\nAddress not valid";
	$p = new Net::Ping("udp",1) or die "\n Ping failed";

#connect to db
my $dataSource = 'DBI:mysql:'.$db_name.':'. $db_hostname;
$db = DBI->connect( $dataSource,$username,$password) or die("Cannot connect to databse");

#push each each valid ip in the subnet
while($ip){
	if($p->ping($ip->ip())){
			push (@addrlist,$ip->ip());
	}
		$ip++;
}
#foreach address in the list check if host answers to snmp
foreach $address (@addrlist){
	($sess,$error)= Net::SNMP->session(
	hostname  => $address,
	Community => $community,
	Timeout => 1,
	Translate =>0,
	Version => 2);
	print $address.":: session error: $error \n" unless ($sess);
	if($sess){
		if($oid eq 'default'){
			foreach $def_oid (@defaults){
				$db->do('INSERT INTO
								host_services (ipaddress, oid)
								VALUES(?,?)',undef,$address,$def_oid);
			}
		}
		else{
			$db->do('INSERT INTO
								host_services (ipaddress, oid)
								VALUES(?,?)',undef,$address,$oid);
		}
	}
}

$sess->close();
$db->disconnect();
