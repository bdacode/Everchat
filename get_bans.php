<?php   // ban or unban a user from a wall. the 'action' argument can be 'ban' or 'unban'
session_start();

require('config.php');

try {
    // require all data
    if(!isset($_POST['user_id']) || !isset($_POST['wall_id']) || !isset($_POST['action'])) throw new Exception('Required data not found.');
    
    // user must be logged in
    if(!isset($_SESSION['userID'])) throw new Exception('User not logged in.');

    // require current user to be admin of the wall id
    if(!in_array($_POST['wall_id'], $_SESSION['admin_for'])) throw new Exception('Permission denied.');

    // create ban record
    if($_POST['action'] == 'ban') {
        $q = mysql_query("INSERT INTO bans (wall_id, user_id) VALUES ($_POST[wall_id], $_POST[user_id])");
        if(mysql_errno() == 1062) throw new Exception(ERROR_3, 3);  // duplicate
        else if(mysql_errno()) throw new Exception(mysql_error());
    // delete ban record
    } else if($_POST['action'] == 'unban') {
        $q = mysql_query("DELETE FROM bans WHERE wall_id = $_POST[wall_id] AND user_id = $_POST[user_id]");   
        if(mysql_errno()) throw new Exception(mysql_error());
    }
    
} catch (Exception $e) {
    if($e->getCode() == 3) $friendly_msg = ERROR_3; // duplicate
    else $friendly_msg = "We couldn't save the ban record for some reason. Everchat people have been notified.";
    echo json_encode(array('success'=>0, 'friendly_msg'=>$friendly_msg, 'system_msg'=>$e->getMessage()));
    error_log($e->getMessage());
    exit;
}

echo json_encode(array('success'=>1));

?>