<?php   // ban or unban a user from a wall. the 'action' argument can be 'ban' or 'unban'
session_start();

require('config.php');

$return = array();

try {
        $q = mysql_query("SELECT * FROM users ORDER BY points DESC LIMIT 300");   
        if(mysql_errno()) throw new Exception(mysql_error());
        $leaders = array();
        while($leader = mysql_fetch_assoc($q)) {
            $leader['created'] = date('Y-m-d', strtotime($leader['created']));
            $leaders[] = $leader;
        }
        $return = array_merge($return, array('leaders'=>$leaders));
    
} catch (Exception $e) {
    $friendly_msg = "We couldn't do that for some reason. Everchat people have been notified.";
    echo json_encode(array('success'=>0, 'friendly_msg'=>$friendly_msg, 'system_msg'=>$e->getMessage()));
    error_log($e->getMessage());
    exit;
}

$return = array_merge($return, array('success'=>1));
echo json_encode($return);

?>