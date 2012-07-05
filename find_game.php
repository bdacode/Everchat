<?php   // find a wall for a player to join. if none available, make a new one.

session_start();
require('config.php');

try {
    // query selects the first with # of webcams less than 15
    $q = mysql_query("SELECT id FROM walls WHERE game_on = 1 AND creator_user_id = 0 AND city_id = 0 AND num_members < 50 " 
                        . " ORDER BY num_members DESC LIMIT 1 ");
    if(mysql_errno()) {
        throw new Exception("Database problem.");
    } else {
        $r = mysql_fetch_assoc($q);
        $wall_id = $r['id'];
    }
    
    // none found, create new one to join
    if(!mysql_num_rows($q)) {
        $q = mysql_query("INSERT INTO walls (name, url_name, created) VALUES ('','',NOW())");
        if(mysql_errno()) throw new Exception("Database problem.");
        $wall_id = mysql_insert_id();
        
        // update with details
        $q = mysql_query("UPDATE walls SET name = '$wall_id', url_name = '$wall_id', game_on = 1 WHERE id = $wall_id");
    }
} catch (Exception $e) {
    echo json_encode(array('success'=>0, 'msg'=>$e->getMessage()));
    exit;
}

echo json_encode(array('success'=>1, 'wall_id'=>$wall_id));
exit;
?>