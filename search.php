<?php   // return room search results

session_start();

require('config.php');

$return = array();

try {
    // require all data
    if(  
        !(!isset($_POST['room_id']) || !is_numeric($_POST['room_id'])) &&
        !(!isset($_POST['search']) || !$_POST['search'])    
    ) throw new Exception('Required data not found.');
    
    // user must be logged in
    if(!isset($_SESSION['userID'])) throw new Exception('User not logged in.');

    // If browsing by city, do that.
    if(isset($_POST['city_id'])) {
        $q = mysql_query("SELECT * FROM walls WHERE city_id = $_POST[city_id]");
        if(mysql_num_rows($q) == 0) throw new Exception('Should have had at least one result.');
    } else if(isset($_POST['search'])) {    // Use search string.
        $search = mysql_real_escape_string(mysql_real_escape_string($_POST['search']));
        $q = mysql_query("SELECT * FROM walls WHERE (name LIKE '%$search%' OR keywords LIKE '%$search%' OR description LIKE '%$search%') AND include_in_search = 1 ORDER BY num_members DESC");

    } else {
        throw new Exception("Couldn't find anything to do.");
    }
    if(mysql_errno()) throw new Exception('Database problem.');
    
    $return['search_string'] = $_POST['search'];
    while($result = mysql_fetch_assoc($q)) {
        $return['rooms'][] = array('room_id'=>$result['id'], 'name'=>utf8_encode($result['name']), 'num_members'=>$result['num_members']);
    }
    
    // Instant entry.
    if(isset($_POST['city_id']) && mysql_num_rows($q)) {
            $return['instant_entry'] = true;
    }
    
} catch (Exception $e) {
    if($e->getCode() == 8) $friendly_msg = ERROR_8; // duplicate
    else $friendly_msg = "We couldn't do that for some reason. Everchat people have been notified.";
    echo json_encode(array('success'=>0, 'friendly_msg'=>$friendly_msg, 'system_msg'=>$e->getMessage()));
    error_log($e->getMessage());
    exit;
}

$return = array_merge($return, array('success'=>1));
echo json_encode($return);

?>