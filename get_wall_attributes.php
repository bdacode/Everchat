<?php // given a name or an id, return wall attributes

require('functions.php');
nocache();

session_start();

require('config.php');

$return_wall_attributes = array();
$return = array();
if(isset($_POST['joining'])) $return['joining'] = true;  // indicates if the user is trying to join the room. used on client side

try {
    if( !isset($_POST['name']) && !isset($_POST['id']) )
            throw new Exception('Room name or ID is required.');

    // get wall
    if(isset($_POST['id'])) {
        if(!is_numeric($_POST['id'])) throw new Exception('Bad ID.');
        $q = mysql_query("SELECT * FROM walls WHERE id = $_POST[id]");
    } else {
        $name = mysql_real_escape_string($_POST['name']);
        $q = mysql_query("SELECT * FROM walls WHERE name = '$name'");
    }
    
    if(mysql_errno()) throw new Exception(mysql_error());
    
    if(!mysql_num_rows($q)) throw new Exception('Room not found.');
    
    $wall = mysql_fetch_assoc($q);
    $wall['name'] = $wall['name'];
    
    // get bans if requested
    if(isset($_POST['ban_check_user_id']) && is_numeric($_POST['ban_check_user_id'])) {
        $q = mysql_query("SELECT * FROM bans WHERE wall_id = $wall[id] AND user_id = $_POST[ban_check_user_id]");
        if(mysql_num_rows($q)) $return['user_is_banned'] = true;
    }
    
    // get banner info if necessary
    if((int)$wall['banner_file_id']) {
        $q = mysql_query("SELECT * FROM files WHERE id = $wall[banner_file_id]");        
        $banner = mysql_fetch_assoc($q);
        $wall['banner_file_name'] = $banner['file_name'];
    } else {
        $wall['banner_file_name'] = '';
    }
    
} catch (Exception $e) {
    echo json_encode(array_merge($return, array('success'=>0, 'msg'=>$e->getMessage())));
    exit;
}

$return_wall_attributes = array(
    'id'=>$wall['id'], 
    'name'=>utf8_encode($wall['name']), 
    'url_name'=>$wall['url_name'], 
    'password'=>$wall['password'], 
    'creator_user_id'=>$wall['creator_user_id'], 
    'game_on'=>(int)$wall['game_on'], 
    'include_in_search'=>(int)$wall['include_in_search'], 
    'city_id'=>(int)$wall['city_id'], 
    'last_object_id'=>(int)$wall['last_object_id'], 
    'last_started_game_object_id'=>(int)$wall['last_started_game_object_id'], 
    'banner_file_id'=>(int)$wall['banner_file_id'],
    'banner_file_name'=>$wall['banner_file_name'],
    'banner_last_object_id'=>$wall['banner_last_object_id']
);
$return = array_merge($return, array('success'=>1, 'wall_attributes'=>$return_wall_attributes));

echo json_encode($return);

?>