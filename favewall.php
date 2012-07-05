<?php 
session_start();

require('config.php');

try {
    if(!isset($_SESSION['userID'])) throw new Exception('Must be logged in to do that.');
    if(!isset($_POST['wall_id']) || !is_numeric($_POST['wall_id'])) throw new Exception('No wall_id found.');
    if(!isset($_POST['wall_name']) || !isset($_POST['url_name'])) throw new Exception('Insufficient data provided.');
    if(!isset($_POST['action']) || !is_numeric($_POST['action'])) throw new Exception('Bad data.');
    
    // attempt to add to favorites
    if((int)$_POST['action'] == 0) {
        $q = mysql_query("DELETE FROM favewalls WHERE wall_id = $_POST[wall_id] AND user_id = $_SESSION[userID]");  
        unset($_SESSION['favewalls'][$_POST['wall_id']]);
    } else {
        $q = mysql_query("INSERT INTO favewalls (wall_id, user_id) VALUES ($_POST[wall_id], $_SESSION[userID])");    
        $_SESSION['favewalls'][$_POST['wall_id']] = true;
    }
    if(mysql_errno()) throw new Exception('Database problem.');

    if((int)$_POST['action'] != 0 && isset($_POST['email']) && $_POST['email']) {
        // send notification email
        $email = array();
        $email['subject'] = "Added " . $_POST['wall_name'] . ' to your favorites';
        $email['body'] = "Here is what you added:<br><br>";
        $email['body'] .= $_POST['wall_name'] . "<br>";
        $email['body'] .= 'http://' . $_POST['url_name'] . '.' . SITE_DOMAIN;
        $email['body'] .= get_email_sig();
        $email['recipients'] = array(
            array('recipient_email'=>$_POST['email'])
        );
        $email['sender_email'] = SITE_EMAIL;
        $email['sender_name'] = SITE_NAME;
        send_email($email);    
   }
    
} catch (Exception $e) {
    echo json_encode(array('success'=>0, 'msg'=>$e->getMessage()));
    exit;
}

echo json_encode(array('success'=>1));

?>