#!/usr/bin/perl
use Net::IP;
use Net::Ping;
use Net::SNMP;
use DBI;
use DBD::mysql;
use Data::Dumper;
require('conf.pl');
use POSIX;

#Check for the right args
if(!defined $ARGV[0] ||($ARGV[0] eq '-h' || $ARGV[0] eq '--help')){
	print "usage: perl get_remote_info.pl hostip\n
					for help use -h or --help \n";
	exit;
}
if(defined $ARGV[0]){
	$ipaddress = $ARGV[0];
}else{
	die "\n please give an ip";
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
foreach $addr (@addrlist){
	#get its info
	$query = $db->prepare('SELECT * FROM host_table WHERE ipaddress = ?');
	$query->bind_param(1,$addr);
	$query->execute();
	while(@host=$query->fetchrow_array()){
		$address = $host[0];
		$community = $host[7];
	}
	$query->finish();

	#ready the snmp session
	($sess,$error)= Net::SNMP->session(
	hostname  => $address,
	Community => $community,
	Timeout => 1,
	Translate =>0,
	Version => 2);
	print $address.":: session error: $error \n" unless ($sess);

	#get its services
	$query = $db->prepare('SELECT * FROM host_services WHERE ipaddress = ? GROUP BY ipaddress,oid');
	$query->bind_param(1,$address);
	$query->execute();
	while(@service=$query->fetchrow_array()){
		push(@services,$service[1]);
	}
	$query->finish();
	#now that we have the services we need to query it
	#note: this part can probably be done better
	# (all in one go probably and somehow getting the mib names in a human readable form?)
	foreach $service (@services){
			print Dumper($service);
		$res = $sess->get_request(-varbindlist=>[$service],);
		if($res){
			$result = $res->{$service};
			$db->do('INSERT INTO
								host_service_results (ipaddress,oid,timestamp,results)
								VALUES(?,?,?,?)',undef,$address,$service,undef,$result);
		}
			if(!defined $res){
				print $sess->error()."\n";
				print $sess->hostname()."\n";
			}

	}
	$sess->close();
}
$db->disconnect();
