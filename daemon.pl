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
	print "usage: perl daemon.pl probing_frequency(in seconds) [ips -v(for message output to stdout)]<--optional \n
					for help use -h or --help \n";
	exit;
}
if(defined $ARGV[0]){
	$sleep_t = $ARGV[0];
}else{
	die "\n please give the interval between scans";
}
if(defined $ARGV[2] && $ARGV[2] eq '-v'){
	$verbosity = '-v';
}
if(defined $ARGV[1] && $ARGV[1] ne '-v'){
	$ipaddrs = $ARGV[1];
	#Check if given ip is a real ip and if its accessible
		$ip = new Net::IP($ipaddrs) or die "\nAddress not valid";
		$p = new Net::Ping("udp",1) or die "\n Ping failed";
}elsif($ARGV[1] eq '-v'){
	$verbosity = '-v';
	}
while(1){
	if( $verbosity eq '-v'){
		print "Probing::".scalar localtime()."\n";
		print qx(perl get_remote_info.pl $ipaddrs $verbosity);
	}else{
		qx(perl get_remote_info.pl $ipaddrs $verbosity);
	}
	sleep($sleep_t);
}
