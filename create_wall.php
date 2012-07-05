<?php
session_start();

require('config.php');

try {
    if(!isset($_POST['name']) || !$_POST['name']) throw new Exception('Name is required.');
    if(!isset($_SESSION['userID'])) throw new Exception('You must log in in order to create a new wall.');
    
    if(strlen($_POST['name']) < 2) throw new Exception('Name must be at least 2 characters.');
    
    // check for existing wall
    $name = mysql_real_escape_string($_POST['name']);
    $q = mysql_query("SELECT * FROM walls WHERE name = '$name'");
    if(mysql_num_rows($q)) throw new Exception('That name already exists. Try another?');
    
    // url name must be unique too/
    // $&+,/:;=?@ RFC 1738
    // "!<>#%{}|\^~[]` not safe
    $url_name = str_replace(str_split("$&+,/:;=?@\"!<>#%{}|\^~[]`-' "),'', $name);
    $q = mysql_query("SELECT * FROM walls WHERE url_name = '$url_name'");
    if(mysql_num_rows($q)) throw new Exception('That name already exists. Try another?');
    
    // create wall 
    $q = mysql_query("INSERT INTO walls (name, url_name, creator_user_id, created) VALUES ('$name', '$url_name', $_SESSION[userID], NOW())");
    if(mysql_errno()) throw new Exception(mysql_error());
    $new_wall_id = mysql_insert_id();
    
    // create admin relationship
    $q = mysql_query("INSERT INTO wall_admins (user_id, wall_id) VALUES ($_SESSION[userID], $new_wall_id)");
    if(mysql_errno()) throw new Exception(mysql_error());
    $_SESSION['admin_for'][$new_wall_id] = true;

    // send notification email
    $email = array();
    $email['body'] = "Here's a record of the new wall so you don't forget.\n\n";
    $email['body'] .= $_POST['name'] . "\n";
    $email['body'] .= 'http://' . $url_name . '.' . SITE_DOMAIN . "\n\n";
    $email['body'] .= "Created by you, $_SESSION[username]." . "\n\n";
    $email['body'] .= "Your admin status is not revokable by other users, so be sure to adminify people who can help you manage the room.";
    $email['subject'] = 'your room ' . $_POST['name'] . ' has been created';
    $email['recipients'] = array(
        array('recipient_email'=>$_SESSION['email'])
    );
    $email['sender_email'] = SITE_EMAIL;
    $email['sender_name'] = SITE_NAME;
    send_email($email);
    
} catch (Exception $e) {
    echo json_encode(array('success'=>0, 'msg'=>$e->getMessage()));
    exit;
}

echo json_encode(array('success'=>1, 'new_wall_id'=>$new_wall_id));

?>