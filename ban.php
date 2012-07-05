<?php   // ban or unban a user from a wall. the 'action' argument can be 'ban' or 'unban'

require('functions.php');
nocache();

session_start();

require('config.php');

$return = array();

try {
    // require all data
    if(!isset($_POST['wall_id']) || !isset($_POST['action'])) throw new Exception('Required data not found.');
    
    // user must be logged in
    if(!isset($_SESSION['userID'])) throw new Exception('User not logged in.');

    // require current user to be admin of the wall id
    if(!in_array($_POST['wall_id'], $_SESSION['admin_for']) && (int)$_SESSION['userID'] != 1) throw new Exception('Permission denied.');

    // create ban record
    if($_POST['action'] == 'get') {
        $q = mysql_query("SELECT users.id AS user_id, users.username AS username, bans.created AS ban_date, bans.reason AS ban_reason FROM users,bans WHERE users.id = bans.user_id AND bans.wall_id = $_POST[wall_id]");   
        if(mysql_errno()) throw new Exception(mysql_error());
        $bans = array();
        while($ban = mysql_fetch_assoc($q)) {
            $ban['user_id'] = (int)$ban['user_id'];
            $ban['ban_date'] = date('M j Y', strtotime($ban['ban_date']));
            $bans[] = $ban;
        }
        $return = array_merge($return, array('bans'=>$bans));
    } else if($_POST['action'] == 'ban') {
        if(!isset($_POST['user_id'])) throw new Exception('Required data not found.');
        $reason = mysql_real_escape_string($_POST['reason']);
        $q = mysql_query("INSERT INTO bans (wall_id, user_id, reason, created) VALUES ($_POST[wall_id], $_POST[user_id], '$reason', NOW())");
        if(mysql_errno() == 1062) throw new Exception(ERROR_3, 3);  // duplicate
        else if(mysql_errno()) throw new Exception(mysql_error());
    // delete ban record
    } else if($_POST['action'] == 'unban') {
        if(!isset($_POST['user_id'])) throw new Exception('Required data not found.');    
        $q = mysql_query("DELETE FROM bans WHERE wall_id = $_POST[wall_id] AND user_id = $_POST[user_id]");   
        if(mysql_errno()) throw new Exception(mysql_error());
    }
    
} catch (Exception $e) {
    if($e->getCode() == 3) $friendly_msg = ERROR_3; // duplicate
    else $friendly_msg = "We couldn't do that for some reason. Everchat people have been notified.";
    echo json_encode(array('success'=>0, 'friendly_msg'=>$friendly_msg, 'system_msg'=>$e->getMessage()));
    error_log($e->getMessage());
    exit;
}

$return = array_merge($return, array('success'=>1));
echo json_encode($return);

?>