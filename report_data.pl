use GD::Graph::linespoints; 
use GD;
use List::Util qw[min max];
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
	print STDOUT 'usage: perl report_data.pl [$oid] [$hostip] [-v] [-o] for help use -h or --help
';
	exit;
}

if(defined $ARGV[0] && $ARGV[0] ne '-v' && $ARGV[0] ne '-o'){
	$oid = $ARGV[0];
}else{
	$oid = -1;
}
if($ARGV[0] eq '-v'){
		$verbosity = '-v';
}


if(defined $ARGV[1] && $ARGV[1] ne '-v'){
	$ipaddress = $ARGV[1];
}else{
	$ipaddress = -1;
}
if($ARGV[1] eq '-v'){
		$verbosity = '-v';
}

if(defined $ARGV[2] && $ARGV[2] eq '-v'){
	$verbosity = '-v';
}
if($ARGV[0] eq '-o' || $ARGV[1] eq '-o' || $ARGV[2] eq '-o'){
	$text_out = 1;
}else{
	$text_out = -1;
	}
if($ipaddress != -1){
	if($verbosity eq '-v'){
		print STDOUT "Getting info for::".$ipaddress."\n";
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

		if($oid == -1){
			print "oid -1\n";
			#get its services
			$query = $db->prepare('SELECT * FROM host_services WHERE ipaddress = ? GROUP BY ipaddress,oid');
			$query->bind_param(1,$address);
			$query->execute();
			while(@service=$query->fetchrow_array()){
				push(@services,$service[1]);
			}
			$query->finish();
		}else{
			push(@services,$oid);
		}
		#now that we have the services we need to query it
		#note to self: this part can probably be done better
		# (all in one go probably and somehow getting the mib names in a human readable form?)
		my @xdata;
		my @ydata;
		foreach $service (@services){
			#get results for specific service
			$query = $db->prepare('SELECT * FROM host_service_results WHERE ipaddress = ? AND oid = ?');
			$query->bind_param(1,$address);
			$query->bind_param(1,$service);
			$query->execute();
			while(@results=$query->fetchrow_array()){
				push(@ydata,$results[3]);
				push(@xdata,$result[2]);
			}
			$query->finish();
				if( $verbosity eq '-v'){
					print STDOUT "Printing results for::".$service." ip::".$ip."\n";
				}
		my @data = (\@xdata, \@ydata);
		my @params = ($address,$service, $graph_path."/".$address."_".$service);
		printGraph(\@params, \@data);
		}
	}
}else{
	if($verbosity eq '-v'){
		print  STDOUT "Getting info for every host \n";
	}
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
			$i++;
			#get its info
			$query = $db->prepare('SELECT * FROM host_table WHERE ipaddress = ?');
			$query->bind_param(1,$addr);
			$query->execute();
			while(@host=$query->fetchrow_array()){
				$address = $host[0];
				$community = $host[7];
			}
			$query->finish();

			if($oid == -1){
				#get its services
				$query = $db->prepare('SELECT * FROM host_services WHERE ipaddress = ? GROUP BY ipaddress,oid');
				$query->bind_param(1,$address);
				$query->execute();
				while(@service=$query->fetchrow_array()){
					push(@services,$service[1]);
				}
				$query->finish();
			}else{
				push(@services,$oid);
			}
			#now that we have the services we need to query it
			#note to self: this part can probably be done better
			# (all in one go probably and somehow getting the mib names in a human readable form?)
			my @xdata;
			my @ydata;
			foreach $service (@services){
				#get results for specific service
				$query = $db->prepare('SELECT * FROM host_service_results WHERE ipaddress = ? AND oid = ?');
				$query->bind_param(1,$address);
				$query->bind_param(2,$service);
				$query->execute();
				while(@results=$query->fetchrow_array()){
					push(@xdata,$results[2]);
					push(@ydata,$results[3]);
				}
				$query->finish();
					if( $verbosity eq '-v'){
						print STDOUT "Printing results for::".$service." ip::".$ip."\n";
					}
			my @data = (\@xdata, \@ydata);
			my @params = ($address,$service, $graph_path."/".$address."_".$service);
			if($text_out != -1){
				printText(\@params,\@data);
			}else{
				printGraph(\@params, \@data);
			}
			undef @data;
			undef @xdata;
			undef @ydata;
			}
		}
}
$db->disconnect();

sub printText{
	my ($pars, $dt) = @_;
	@data = @$dt;
	@params = @$pars;
	$ip = $params[0];
	$oid = $params[1];
	$file = $params[2];
	my $timestamp = localtime(time);
	#open(FILE, ">>" ) or die $!;
	print "Writing time: ". $timestamp. " for ". $ip. " ::  ".$oid."\n";
	my $times = $data[0];
	my $values = $data[1];
	my $i = 0;		
	#print Dumper($data[1]);
	foreach $t (@$times){
		print $t." -> ". @$values[$i]."\n";
		$i++;
	}
	close FILE;
}
sub printGraph{
	my ($pars, $dt) = @_;
	@data = @$dt;
	@params = @$pars;
	$ip = $params[0];
	$oid = $params[1];
	$graph_file = $params[2];
	
	$my_graph = new GD::Graph::linespoints(800,500);

	#print Dumper(@data);
  $my_graph->set( 
      x_label           => 'Time',
      y_label           => 'Values',
	  title             => 'Results for '.$oid,
      y_tick_number     => 5,
      y_label_skip      => 1,
	#x_tick_number => 5,
	#x_label_skip => 2, 
	 x_labels_vertical => 1, 
  ) or die $graph->error;

	my $gd = $my_graph->plot(\@data) or die $my_graph->error;
	#$img = $my_graph->gd();
	open(IMG, ">","$graph_file") or die $!;
	binmode IMG;
	print IMG $gd->gif;
	close IMG;
}
