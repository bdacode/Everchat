<?php

// This script runs like a service on the server, sending emails and marking them as sent in the database. 
require_once "Swift.php";
require_once "Swift/Connection/SMTP.php";
require_once "config.php";

foreach($argv AS $k=>$v) {
	if($v == '-s') define('SMTP_HOST', $argv[(int)$k+1]);
}

if(!defined('SMTP_HOST')) define('SMTP_HOST', 'localhost');

define('SLEEP_TIME',3); // for the loop 

// End settings //

// infinite loop
while(1) {

    if(!$mysql) {
        $mysql = mysql_connect('localhost', 'root', '26810a43');
    }

    // SELECT the next 20 emails.
    $results = mysql_query('
        SELECT emails.*, email_recipients.recipient_email AS recipient_email, email_recipients.recipient_name AS recipient_name, email_recipients.id AS recipient_id, email_recipients.extras AS extras
        FROM emails, email_recipients
        WHERE emails.id = email_recipients.email_id 
        AND email_recipients.sent = 0 
        ORDER BY created ASC LIMIT 20'
    );

    if(mysql_errno()) { 
        echo date("F j, Y, g:i a") . " SELECT query failed: " . mysql_error() . "\n";
        sleep(SLEEP_TIME);
        continue;
    }
    
    if(mysql_num_rows($results) == 0) {
        echo date("F j, Y, g:i a") . " No emails to send right now.\n";
        sleep(SLEEP_TIME);
        continue;
    }

    // Loop through the emails, attempting to send each one.
    // After each send, mark the email as sent with an SQL statement.
    while($email = mysql_fetch_assoc($results)) {
    
        try {
            // Start Swift
            $smtp = new Swift_Connection_SMTP(SMTP_HOST);
            $swift = new Swift($smtp);
    
        } catch(Exception $e) {
            echo date("F j, Y, g:i a") . " Exception thrown creating SMTP Connection for email #$email[id] on SMTP server " . SMTP_HOST . " \n";
            continue;
        }
    
        // Replace extras
        if($email['extras']) $email['extras'] = json_decode($email['extras'], true);
        if(is_array($email['extras'])) {
            foreach($email['extras'] AS $k=>$v) {
                $email['body'] = str_replace($k, $v, $email['body']);
            }
        }
        
        // Create the message
        $message = new Swift_Message($email['subject'], $email['body'], ($email['html'] ? 'text/html' : 'text/plain'), '8bit', 'utf-8');
        if($email['reply_to_email']) $message->setReplyTo($email['reply_to_email']);
        else $message->setReplyTo(SITE_REPLY_TO_EMAIL);
    
        // Now check if Swift actually sends it
        try {
            $send = $swift->send($message, new Swift_Address($email['recipient_email'], $email['recipient_name']), new Swift_Address($email['sender_email'], $email['sender_name']));
            if($send) {
                echo "Sent email #" . $email['id'] . "\n";
                // Mark email as sent (incomplete)
                $mark_as_sent = mysql_query("
                        UPDATE email_recipients
                        SET email_recipients.sent = 1, email_recipients.date_sent = NOW()
                        WHERE email_recipients.id = $email[recipient_id]"
                );
                if($mark_as_sent == false) {
                    echo date("F j, Y, g:i a") . " Problem marking email email #" . $email['id'] . " as sent!\n";
                }
            } else {
                echo date("F j, Y, g:i a") . " Failed to send email #" . $email['id'] . "\n"; 
                sleep(3);
            }
            $swift->disconnect();
        } catch(Swift_Connection_Exception $e) {
            echo date("F j, Y, g:i a") . " Exception thrown for email #$email[id]" . " " . $e->getMessage() . "\n";
            $swift->disconnect();
            continue;
        } catch(Swift_Message_MimeException $e) {
            echo "There was an unexpected problem building the email: " . $e->getMessage() . "\n";
        }
        
    }
    sleep(SLEEP_TIME);
}
mysql_free_result($results);
mysql_close($mysql);

?>