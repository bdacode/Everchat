<?php   // script's sole purpose is to update a walls.num_members field in the database

header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
header("Cache-Control: no-store, no-cache, must-revalidate");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

session_start();
require('config.php');

try {
    if(!isset($_SESSION['userID']) || !isset($_POST['room_id']) || !is_numeric($_POST['room_id']) || !isset($_POST['num_members']) || !is_numeric($_POST['num_members'])
    ) throw new Exception("Bad data.");

    // update
    $q = mysql_query("UPDATE walls SET num_members = $_POST[num_members] WHERE id = $_POST[room_id]");
    if(mysql_errno()) throw new Exception("Database problem.");
    
} catch (Exception $e) {
    $friendly_msg = "There was a problem doing that. Everchat people have been notified.";
    echo json_encode(array('success'=>0, 'msg'=>$friendly_msg, 'system_msg'=>$e->getMessage()));
    error_log($e->getMessage());
    exit;
}

echo json_encode(array('success'=>1));

