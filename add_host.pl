#!/usr/bin/perl
use Net::IP;
use Net::Ping;
use Net::SNMP;
use DBI;
use DBD::mysql;
use Data::Dumper;
require('conf.pl');
use POSIX;


$sysName ='1.3.6.1.2.1.1.5.0';
$sysDescr ='1.3.6.1.2.1.1.1.0';
$ifNumber = '1.3.6.1.2.1.2.1.0';
$ipv4forwarding = '1.3.6.1.2.1.4.1.0';


#Check for the right args
if(!defined $ARGV[0] ||($ARGV[0] eq '-h' || $ARGV[0] eq '--help')){
	print 'usage: perl add_host.pl hostip host_identifier community
e.g. perl add_host.pl 192.168.1.23 the_thing public
or you can use it with a net mask
perl add_host.pl 192.168.1.23/23  the_thing public
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
	$identifier = $ARGV[1];
}else{
	die "\n please give a hostname";
}
if(defined $ARGV[2]){
	$community = $ARGV[2];
}else{
	$community = 'pulic';
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
	#if session is valid get some more info
	if($sess){
		$res = $sess->get_request(-varbindlist=>[$sysName,$sysDescr,$ifNumber,$ipv4forwarding],);
		# or die "$address could not validate request \n";
		if(!defined $res){
			print $sess->error()."\n";
			print $sess->hostname()."\n";
		}
		if($res){
			$SysName = $res->{$sysName};
			$Descr = $res->{$sysDescr};
			$IfNo = $res->{$ifNumber};
			$isForwarding = $res->{$ipv4forwarding};
			$db->do('INSERT INTO
								host_table (ipaddress,
														identifier,
														hostname,
														sys_description,
														no_of_inf,
														ip_forwarding,
														community_string)
								VALUES(?,?,?,?,?,?,?) ON DUPLICATE KEY UPDATE
									identifier = VALUES(identifier),
									hostname=VALUES(hostname),
									sys_description=VALUES(sys_description),
									no_of_inf=VALUES(no_of_inf),
									ip_forwarding=VALUES(ip_forwarding),
									community_string=VALUES(community_string)',
									undef,$address,$identifier,$SysName,$Descr,$IfNo,$isForwarding,$community);
		}
	}
}
$sess->close();
$db->disconnect();
