<?php
    require_once('functions.php'); // frequently used functions

	// Define.
	define('SITE_NAME', 'Everchat');
	define('SITE_EMAIL', 'mail@ever-chat.com');
	define('SITE_REPLY_TO_EMAIL', 'eric@ever-chat.com');
    define('SITE_DOMAIN', 'ever-chat.com');
	define('SITE_URL', 'http://ever-chat.com');
	define('HASH_KEY', 'thekeyboardismightierthanthesword');
	define('LOCAL_FILES_DIR', '/usr/local/nginx/html/files');
	define('TRIVIA_FILES_DIR', '/usr/local/nginx/html/files');
	define('P2P_CHUNK_SIZE', 32000);
	
	// Connect to database.
    $mysql = mysql_connect('localhost', 'root', '26810a43');
	mysql_select_db('everchat');
	
	// generic function for using the email spooler
	function send_email($options) {
	    $email_fields = array('sender_email','sender_name','reply_to_email','subject','body','html');
        
        // validate and create empty fields if necessary
        if(!isset($options['sender_email'])) return false;    // required
        if(!isset($options['sender_name'])) $options['sender_name'] = '';
        if(!isset($options['reply_to_email'])) $options['reply_to_email'] = '';
        if(!isset($options['subject'])) $options['subject'] = 'no subject';
        if(!isset($options['body'])) return false;
        if(!isset($options['html'])) $options['html'] = 1;
        
        foreach($options AS $k=>$v) {
            if(is_string($options[$k])) $options[$k] = mysql_real_escape_string($v);
        }
        
        // save the email
        $q = mysql_query("INSERT INTO emails (sender_email,sender_name,reply_to_email, subject,body,created,html)
                                            VALUES('$options[sender_email]','$options[sender_name]','$options[reply_to_email]','$options[subject]','$options[body]',NOW(),$options[html])"
        );

        // use email's id to create recipients
        if(isset($options['recipients'])) {
            // now use the email's id to create recipients
            $email_id = mysql_insert_id();
            
            // save recipient records
            foreach($options['recipients'] AS $recipient) {
                if(!isset($recipient['recipient_email'])) continue;
                if(!isset($recipient['recipient_name'])) $recipient['recipient_name'] = '';
                if(!isset($recipient['extras'])) $recipient['extras'] = '';
                $q = mysql_query("INSERT INTO email_recipients (email_id, recipient_email, recipient_name, extras, created) VALUES($email_id, '$recipient[recipient_email]', '$recipient[recipient_name]', '$recipient[extras]', NOW())");
            }
        }
	}
?>