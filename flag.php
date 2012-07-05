<?php   // ban or unban a user from a wall. the 'action' argument can be 'ban' or 'unban'
session_start();

require('config.php');

$return = array();

try {
    // require all data
    if(!isset($_POST['wall_id']) || !isset($_POST['user_id'])) throw new Exception('Required data not found.');
    
    // user must be logged in
    if(!isset($_SESSION['userID'])) throw new Exception('User not logged in.');

    $reason = mysql_real_escape_string($_POST['reason']);
    $q = mysql_query("INSERT INTO flags (wall_id, user_id, reason, created) VALUES ($_POST[wall_id], $_POST[user_id], '$reason', NOW())");
    if(mysql_errno()) throw new Exception(mysql_error());

} catch (Exception $e) {
    $friendly_msg = "We couldn't do that for some reason. Everchat people have been notified.";
    echo json_encode(array('success'=>0, 'friendly_msg'=>$friendly_msg, 'system_msg'=>$e->getMessage()));
    error_log($e->getMessage());
    exit;
}

$return = array_merge($return, array('success'=>1));
echo json_encode($return);

?>