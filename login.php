<?php
session_start();

require('config.php');

function getUser($fbid) {
    return mysql_query("SELECT id AS userID, username AS username, email AS email, num_logins AS num_logins, location AS location, points AS points FROM users WHERE fbid = $fbid");
}

try {
    if(     ( !isset($_POST['fbid']) || !is_numeric($_POST['fbid']) || !$_POST['fbid'])
            || ( !isset($_POST['email']) )
            || ( !isset($_POST['location']) )
    ) throw new Exception('Bad data.');
    
    // Get existing user.
    $q = getUser($_POST['fbid']);
    if(mysql_errno()) throw new Exception('Query failed.');

    // If not found create new user.
    if(!mysql_num_rows($q)) {
        $q = mysql_query("INSERT INTO users (fbid, created) VALUES ($_POST[fbid], NOW())");
        if(mysql_errno()) throw new Exception('Create user failed.');
        $q = getUser($_POST['fbid']);
        
        if(isset($_POST['email']) && $_POST['email']) {
            // Send a welcome email. 
            $email = array();
            $email['subject'] = "some info about Everchat";
            $email['body'] =<<<EOD
Hey $_POST[first_name],<br><br>

You logged into the site for the first time, so here is some info about how it works.<br><br>

Everchat is a casual place to hang out with friends and new faces on the internet. In the past, group video chat has been problematic because sites like Chatroulette could not keep out the obstinate exhibitionists of the world. This is why Everchat requires logins with Facebook. <br><br>

Another aspect of Everchat is games. Currently a trivia game is running that everyone can play at the same time. If you don't want to play, close the window (and use the Play Game button to bring it back).<br><br>

Creating private rooms is a one-click venture.  On the home screen type a name and click Create.  You can set a password, turn games on or off,  upload a banner, and adminify other people. Bans are associated with Facebook accounts, so unwanteds can't come back unless they go through another Facebook account.<br><br>

That's all for now...invite some people and enjoy!<br><br>

P.S. if you have a Mac, a program called CamTwist can put incredible effects in your webcam broadcast.
EOD;

            $email['body'] .= get_email_sig();

            $email['html'] = 1;

            $email['recipients'] = array(
                array('recipient_email'=>$_POST['email'])
            );
            
            $email['sender_name'] = SITE_NAME;
            $email['sender_email'] = 'eric@' . SITE_DOMAIN;
        
            if(send_email($email) === false) throw new Exception('Problem sending email.');
        }
    }
    
    // should have a user now
    $user = mysql_fetch_assoc($q);
        
    // update if location or email is different
    $update_fields = array();
    if(     ($user['email'] != $_POST['email']) || ($user['location'] != $_POST['location'])  ) {
        if(isset($_POST['email'])) $update_fields[] = " email = '" . mysql_real_escape_string($_POST['email']) . "' ";
        if(isset($_POST['location'])) $update_fields[] = " location = '" . mysql_real_escape_string($_POST['location']) . "' ";

        $set_string = implode(',',$update_fields);    
        if(count($update_fields) > 0) $q = mysql_query("UPDATE users SET $set_string WHERE fbid = $_POST[fbid]");
        if(mysql_errno()) throw new Exception('Update user record failed.');
    }

    // admin for any walls?
    $q = mysql_query("SELECT wall_id FROM wall_admins WHERE user_id = $user[userID]");
    $admin_for = $r = array();
    while($r = mysql_fetch_assoc($q)) {
        $admin_for[$r['wall_id']] = true;
    }
    
    // favorite walls?
    $q = mysql_query("SELECT wall_id, name, num_members FROM favewalls,walls WHERE user_id = $user[userID] AND favewalls.wall_id = walls.id");
    $favewalls = $r = array();
    while($r = mysql_fetch_assoc($q)) {
        $favewalls[$r['wall_id']] = $r;
    }
    
    // increment number of logins
    $q = mysql_query("UPDATE users SET num_logins = (num_logins+1) WHERE id = $user[userID]");
} catch (Exception $e) {
    echo json_encode(array('success'=>0, 'msg'=>$e->getMessage()));
    exit;
}

echo json_encode(array('success'=>1, 'userID'=>$user['userID'], 'username'=>$user['username'], 'num_logins'=>$user['num_logins'], 'points'=>$user['points'], 'admin_for'=>$admin_for, 'favewalls'=>$favewalls));

// assign session variables
$_SESSION['userID'] = $user['userID'];
$_SESSION['admin_for'] = $admin_for;
$_SESSION['favewalls'] = $favewalls;
$_SESSION['username'] = $user['username'];
$_SESSION['email'] = $user['email'];

?>