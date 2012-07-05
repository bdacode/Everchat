<?php
session_start();

require('config.php');

try {
    // require wall_id, and target_user_id
    if(!isset($_POST['wall_id']) || !isset($_POST['target_user_id'])) throw new Exception('Missing required data.');
    if(!is_numeric($_POST['wall_id']) || !is_numeric($_POST['target_user_id'])) throw new Exception('Bad data.');

    // require current user to be admin of the wall id
    if(!in_array($_POST['wall_id'], $_SESSION['admin_for'])) throw new Exception('Permission denied.');
    
    // attempt to adminify
    $q = mysql_query("INSERT INTO wall_admins (wall_id, user_id) VALUES ($_POST[wall_id], $_POST[target_user_id])");
    if(mysql_errno() == 1062) throw new Exception('User is already adminified.');   // duplicate key error number
    else if(mysql_errno()) throw new Exception(mysql_error());
    
    // get target user's email address
    $q = mysql_query("SELECT email FROM users WHERE id = $_POST[target_user_id]");
    $target_user = mysql_fetch_assoc($q);

    // send notification email
    $email = array();
    $email['subject'] = 'you\'ve been adminified in ' . $_POST['wall_name'] . ' by ' . $_SESSION['username'];
    $email['body'] = "You're an admin for $_POST[wall_name]. That means you can change settings "
                    . "for the wall and also kick out disruptive users. This only works if you "
                    . "are logged into the site (some walls don't require logins). \n\n";
    $email['body'] .= $_POST['wall_name'] . ': http://' . $_POST['url_name'] . '.' . SITE_DOMAIN . "\n";
    $email['recipients'] = array(
        array('recipient_email'=>$target_user['email'])
    );
    $email['sender_email'] = SITE_EMAIL;
    $email['sender_name'] = SITE_NAME;
    send_email($email);
    
} catch (Exception $e) {
    echo json_encode(array('success'=>0, 'msg'=>$e->getMessage()));
    exit;
}

echo json_encode(array('success'=>1));

?>