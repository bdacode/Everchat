<?php // frequently used functions (more than twice) 

function validate_email($email) {
    return (bool)preg_match("/[a-z0-9!#$%&'*+\/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+\/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?/i", $email);
}

// returns number of milliseconds since epoch
function mstime() {
    $times = explode(' ', microtime()); 
    $now = (int)($times[0]*1000) + (int)$times[1]*1000;
    return number_format($now,0,'.','');
}

function nocache() {
    header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
    header("Cache-Control: no-store, no-cache, must-revalidate");
    header("Cache-Control: post-check=0, pre-check=0", false);
    header("Pragma: no-cache");
}

function get_email_sig($html=true) {
    if($html) {
        $br = '<br>';
    } else {
        $br = '';
    }
    return <<<EOD
$br$br

-- $br
http://ever-chat.com $br
Nashville, TN $br
created by Eric Winchell $br
EOD;
}

// master list of error codes
$error_msgs = array();

define('DEFAULT_ERROR_MSG', 'There was a problem doing that. Everchat people have been notified.');
define('ERROR_0', 'No activated games found.');
define('ERROR_1', 'Game not found.');
define('ERROR_2', 'Database problem while retrieving game.');
define('ERROR_3', 'The user is already banned from this room.');
define('ERROR_4', 'getGames() requires wall_id.');
define('ERROR_5', 'getGames() database query problem.');
define('ERROR_6', 'Games could not be created.');
define('ERROR_7', 'Round creation failed.');
define('ERROR_8', 'Search error.');
?>