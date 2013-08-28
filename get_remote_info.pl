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
if($ARGV[0] eq '-h' || $ARGV[0] eq '--help'){
	print STDOUT "usage: perl get_remote_info.pl [hostip -v]<--optional\n
					for help use -h or --help \n";
	exit;
}
if(defined $ARGV[0] && $ARGV[0] ne '-v'){
	$ipaddress = $ARGV[0];
}else{
	$ipaddress = -1;
}
if($ARGV[0] eq '-v'){
		$verbosity = '-v';
}

if(defined $ARGV[1] && $ARGV[1] eq '-v'){
	$verbosity = '-v';
}

if($ipaddress != -1){
	 print STDOUT "Getting info for::".$ipaddress."\n";
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
		print STDOUT $address.":: session error: $error \n" unless ($sess);

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
			$res = $sess->get_request(-varbindlist=>[$service],);
			if($res){
				if( $verbosity eq '-v'){
					print STDOUT "Adding results for::".$service." ip::".$ip."\n";
				}
				$result = $res->{$service};
				$db->do('INSERT INTO
									host_service_results (ipaddress,oid,timestamp,results)
									VALUES(?,?,?,?)',undef,$address,$service,undef,$result);
			}
				if(!defined $res){
					print STDOUT $sess->error()."\n";
					print STDOUT $sess->hostname()."\n";
				}

		}
		$sess->close();
	}
}else{
	print  STDOUT "Getting info for every host \n";
	#connect to db
	my $dataSource = 'DBI:mysql:'.$db_name.':'. $db_hostname;
	$db = DBI->connect( $dataSource,$username,$password) or die("Cannot connect to databse");

	#get info for everything
		$query = $db->prepare('SELECT * FROM host_table');
		$query->execute();
		while(@host=$query->fetchrow_array()){
			push(@addresses,$host[0]);
			push(@community,$host[7]);
		}
		$query->finish();
		$i = 0;
		foreach $address (@addresses){
			#ready the snmp session
			($sess,$error)= Net::SNMP->session(
			hostname  => $address,
			Community => $community[$i],
			Timeout => 1,
			Translate =>0,
			Version => 2);
			print STDOUT $address.":: session error: $error \n" unless ($sess);
			$i++;
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
					#print Dumper($service);
				$res = $sess->get_request(-varbindlist=>[$service],);
				if($res){
					if( $verbosity eq '-v'){
						print STDOUT "Adding results for::".$service." ip::".$address."\n";
					}
					$result = $res->{$service};
					$db->do('INSERT INTO
										host_service_results (ipaddress,oid,timestamp,results)
										VALUES(?,?,?,?)',undef,$address,$service,undef,$result);
				}
					if(!defined $res){
						print STDOUT $sess->error()."\n";
						print STDOUT $sess->hostname()."\n";
					}

			}
			$sess->close();
		}
}
$db->disconnect();
