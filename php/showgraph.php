<?php
require_once ('webroot.php');
require_once ('includes/basics.php');
require_once ('includes/jpgraph/jpgraph.php');
require_once ('includes/jpgraph/jpgraph_line.php');
require_once ('includes/jpgraph/jpgraph_bar.php');
require_once ('getGraphLibDatagramInfo.php');
require_once ('getGraphLibFragmentsInfo.php');
require_once ('generateGraph.php');
if (!isset($_SESSION['username'])) {
    header('index.php');
}
if (!isset($_SESSION['ipaddress'])) {
    $_SESSION['ipaddress'] = $_GET['address'];
}
$recent = $_GET['recent'];
$ipaddress = $_SESSION['ipaddress'];
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

    <head>
        <title>IP Monitoring System | Statistics</title>
        <link rel="stylesheet" type="text/css" href="css/style.css" />
        <link  href="http://fonts.googleapis.com/css?family=Ubuntu:300,300italic,regular,italic,500,500italic,bold,bolditalic" rel="stylesheet" type="text/css" />
    </head>

    <body>

        <div class="header">

            <div class="container">

                <div class="nav">

                    <ul>
                        <li><a class="viewnetworkinfo" href="networkmonitor.php">View Network Info</a></li>
                        <li><a class="faq" href="#">FAQ</a></li>
                        <li><form action="logout.php"><input type="submit" value="Logout"/></form></li>
                    </ul>

                </div>

                <h1>IP Monitoring System</h1>

            </div><!--Container-->

        </div><!--Header-->
        <div class="content">

            <div class="container">

                <?php
                echo "<h1 class=\"selected_ip\" id='ip'>" . $ipaddress . "</h1>";
                $oids = get_oids_for_host($ipaddress);
                $services = array();
                if($oids != false){
									$i = 0;
									while($oid = mysql_fetch_assoc($oids)){
										$services[$i] = $oid['oid'];
										$i++;
									}
								}else{
									echo mysql_error();
									$services[0] = "No services for this host";
								}
                ?>
                <form  method="get" action="showgraph.php">
                    <p> <select id="selected" name="option">
													<?php foreach($services as $value){ ?>
													<option value="<?php echo $value;?>"><?php echo $value;?></option>
													<?php }?>
                        </select>
                        <?php
                        echo "<input type='hidden' name='address' value='" . $ipaddress . "'/>";
                        echo "<input type='hidden' name='recent' value='false'/>";
                        ?>
                        <input type="submit" name="submit" value="Submit"/>
                    </p>
                </form>
                <div class="clear"></div>
                <div class="clear"></div>
                <div id="graph">
                    <?php
                    if (isset($_GET['option']) || $recent == "true") {
                        $option = $_GET['option'];
                        $data = array();
												$results =  get_results_for_oid_host($ipaddress, $option);
												if($results != false){
													$i = 0;
													while($line = mysql_fetch_assoc($results)){
														$data[$i] = $line;
														$i++;
													}
												}else{
													echo mysql_error();
													$data[0] = "No data host";
												}
											?>
											Info:</br>
											Service monitored since:
											<?php
											$results = array();
											foreach($data as $subarray){
												array_push($results,$subarray['results']);
											}
											if(is_numeric($results[0]) &&
												 !count(array_unique($results)) === 1) {

												$d = plot($data,$option);
												echo $d['min'];?>
												<br>
												Average value of the service
												<?php echo $d['avg'];
												echo "<table style=\"width:100%;\" class=\"graph_table\">
																<tr><td>";
												echo "<img style=\"width:100%;\"src=\"images/graph.jpg\"alt=\"the_graph\"></td></tr></table>";
                      }elseif(count(array_unique($results)) === 1){
												$d = plot($data,$option);
												?>
											Info:</br>
											Service monitored since:
											<?php
												echo $d['min'];
												echo "</br>Value of ".$option." is the same for all counts:". $results[0];
											}elseif(!is_numeric($data[0]['results']) && count(array_unique($results)) > 1){
												echo "The list of non numeric values is:<ul>";
												foreach($data as $subarray){
													echo "</li><li>";
													foreach($subarray as $key=>$value){
														echo "   ".$key."->".$value."</br>";
													}
												}
												echo "</ul>";
											}
                    }
                    ?>
                </div>
            </div>
            <!--Container-->

        </div><!--Content-->



        <div class="footer">

            <div class="container">

                <p>2011 &copy; IP Monitoring System</p>

            </div><!--Container-->

        </div><!--Footer-->

    </body>

</html>

