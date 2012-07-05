<?php
session_start();

require('config.php');

try {
    // require all data
    if(!isset($_POST['user_id'])) throw new Exception('Required data not found.');
    
    // user must be logged in
    if(!isset($_SESSION['userID'])) throw new Exception('User not logged in.');

    $update_fields = array();
    if(isset($_POST['username'])) {
        // ensure unique username
//        $u = mysql_query("SELECT * FROM users WHERE username = '$_POST[username]'");
//        if(mysql_num_rows($u)) throw new Exception("Username $_POST[username] is already in use. Try another?");
        $update_fields[] = " username = '" . mysql_real_escape_string($_POST['username']) . "' ";
    }
    if(isset($_POST['email'])) $update_fields[] = " email = '" . mysql_real_escape_string($_POST['email']) . "' ";
    
    $set_string = implode(',',$update_fields);
    
    if(count($update_fields) > 0) $q = mysql_query("UPDATE users SET $set_string WHERE id = $_POST[user_id]");
    if(mysql_errno()) throw new Exception(mysql_error());
    
} catch (Exception $e) {
    echo json_encode(array('success'=>0, 'msg'=>$e->getMessage()));
    exit;
}

echo json_encode(array('success'=>1, 'username'=>$_POST['username']));

?>