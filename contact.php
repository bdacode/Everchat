<?php   // Save and send a message from a contact form.
session_start();

require('config.php');

$return = array();

try {
    if(!isset($_POST['user_id']) || !isset($_POST['facebook_id']) || !isset($_SESSION['userID'])) throw new Exception('You must be logged in to do that.');    
    if(!isset($_POST['message']) || !$_POST['message']) throw new Exception('Message is required.'); 

    // Passed validation. Send the email. 
    $email = array();
    $email['subject'] = "*** Everchat message from $_POST[name]";
    $email['body'] = "$_POST[name]\n http://facebook.com/profile.php?id=$_POST[facebook_id]\n\n";
    $email['body'] .= $_POST['message'] . "\n\n";

    $email['recipients'] = array(
        array('recipient_email'=>SITE_EMAIL)
    );
    if(isset($_POST['email']) && $_POST['email']) $email['reply_to_email'] = $_POST['email'];
    
    $email['sender_name'] = $_POST['name'];
    $email['sender_email'] = 'contact@' . SITE_DOMAIN;
    
    if(send_email($email) === false) throw new Exception('Problem sending email.');

} catch (Exception $e) {
    $friendly_msg = "We couldn't do that for some reason. Everchat people have been notified.";
    echo json_encode(array('success'=>0, 'friendly_msg'=>$friendly_msg, 'system_msg'=>$e->getMessage()));
    error_log($e->getMessage());
    exit;
}

echo json_encode(array('success'=>1));

?>