<?php
session_start();

require('config.php');

$objects = array(); // return objects to be replicated in JSON format

try {

    // require all data
    if(!isset($_POST['id']) || !isset($_POST['password']) || !is_numeric($_POST['id'])) throw new Exception('Required data not found.');
    
    // user must be logged in
    if(!isset($_SESSION['userID'])) throw new Exception('User not logged in.');
    
    // user must be admin for the wall
    if(!in_array($_POST['id'], $_SESSION['admin_for']) && (int)$_SESSION['userID'] != 1) throw new Exception('User is not adminified for this wall.');

    // lock wall 
    $l = mysql_query("LOCK TABLES walls, files WRITE");

    // get the starting object index
    $w = mysql_query("SELECT * FROM walls WHERE id = $_POST[id]");
    $wall = mysql_fetch_assoc($w);
    $object_id = $wall['last_object_id'];
    
    // get banner info if necessary
    if((int)$wall['banner_file_id']) {
        $q = mysql_query("SELECT * FROM files WHERE id = $wall[banner_file_id]");        
        $banner = mysql_fetch_assoc($q);
    }
    
    // update password separately    
    $password = mysql_real_escape_string($_POST['password']);
    if($_POST['password'] != 'nochange999') $q = mysql_query("UPDATE walls SET password = '$password' WHERE id = $_POST[id]");
    if(mysql_errno()) throw new Exception(mysql_error());
    
    if(
        (int)$_POST['game_on'] != (int)$wall['game_on'] ||
        (int)$_POST['include_in_search'] != (int)$wall['include_in_search'] || 
        (int)$_POST['city_id'] != (int)$wall['city_id']
    ) {
        if(!is_numeric($_POST['game_on']) || !is_numeric($_POST['include_in_search']) || !is_numeric($_POST['city_id'])) throw new Exception('Bad data.');
        $q = mysql_query("UPDATE walls SET game_on = $_POST[game_on], include_in_search = $_POST[include_in_search], city_id = $_POST[city_id] WHERE id = $_POST[id]");
        if(mysql_errno()) throw new Exception(mysql_error());
    }
        
    if((int)$_POST['game_on'] != (int)$wall['game_on']) {        
        $object_id++;
        if((int)$_POST['game_on'] == 1) {    // on
            $objects[$object_id] = array('type'=>'games on');
        } else {    // off
            $objects[$object_id] = array('type'=>'games off');        
        }
    }

    // banner
    if(isset($_POST['banner_action'])) {    // anything to do?
    
        // clear
        if($_POST['banner_action'] == 'clear' && (int)$wall['banner_file_id']) {
            $q = mysql_query("UPDATE walls SET banner_file_id = 0 WHERE id = $_POST[id]");
            if($wall['banner_file_id']) {
                   $q = mysql_query("DELETE FROM files WHERE id = $wall[banner_file_id]");
                   unlink(LOCAL_FILES_DIR . '/' . $banner['file_name']);
            }
            
            $object_id++;
            $clear_banner_object = array();
            $clear_banner_object['type'] = 'clear room banner';
            $objects[$object_id] = $clear_banner_object;
            
            $w = mysql_query("UPDATE walls SET banner_last_object_id = $object_id WHERE id = $_POST[id]");

        // new
        } else if(isset($_POST['banner_action']) && $_POST['banner_action'] == 'new') {
            if(!isset($_FILES['banner']) || !$_FILES['banner']['size']) throw new Exception('Banner upload file not found.');
            if($_FILES['banner']['size'] > 100000) throw new Exception('Max file size is 100k.');
            if(!preg_match('/^.*\.(jpg|jpeg|png|gif)$/i', $_FILES['banner']['name'])) throw new Exception("Valid file types are JPEG, PNG, and GIF.");
            
            // determine file type
            if(preg_match('/^.*\.(jpg|jpeg)$/i', $_FILES['banner']['name'])) {
                $file_type_id = 2;
            } else if(preg_match('/^.*\.(png)$/i', $_FILES['banner']['name'])) {
                $file_type_id = 1;
            } else if(preg_match('/^.*\.(gif)$/i', $_FILES['banner']['name'])) {
                $file_type_id = 3;    
            }

            $banner_filename = 'banner-' . $wall['id'] . '-' . rand(0,10000) . '.';
            switch($file_type_id) {
                    case 2:
                        $banner_filename .= 'jpg';
                        break;
                    case 1:
                        $banner_filename .= 'png';
                        break;
                    case 3:
                        $banner_filename .= 'gif';
                        break;
            }
            if(!move_uploaded_file($_FILES['banner']['tmp_name'], LOCAL_FILES_DIR . '/'  . $banner_filename)) throw new Exception("Unable to move file from temporary location to permanent location. Filename:" . $banner_filename);

            // create a file record
            $q = mysql_query("INSERT INTO files (file_type_id, file_size, file_name) VALUES ($file_type_id, {$_FILES['banner']['size']}, '$banner_filename')");
            if(mysql_errno()) throw new Exception(mysql_error());
            $banner_file_id = mysql_insert_id();
            
            // delete old one if necessary
            if($wall['banner_file_id']) {
                   $q = mysql_query("DELETE FROM files WHERE id = $wall[banner_file_id]");
                   unlink(LOCAL_FILES_DIR . '/' . $banner['file_name']);
            }
            
            // determine number of P2P objects required for the banner. it will be shared by the seeders
            // in order to do a live update for everyone
            $object_id++;
            $new_banner_object = array();
            $objects[$object_id] = &$new_banner_object;
            
            $object_id++;
            $num_banner_chunks = floor($_FILES['banner']['size']/P2P_CHUNK_SIZE)+1;  // will be at least 1
            $new_banner_object['type'] = 'seed room banner';
            $new_banner_object['start_object_id'] = $object_id;
            $new_banner_object['end_object_id'] = $object_id + ($num_banner_chunks-1);
            $new_banner_object['banner_file_id'] = $banner_file_id;
            $object_id += ($num_banner_chunks-1);
            
            $q = mysql_query("UPDATE walls SET banner_file_id = $banner_file_id, banner_last_object_id = $object_id WHERE id = $_POST[id]");
        }
    }
    
    $w = mysql_query("UPDATE walls SET last_object_id = $object_id WHERE id = $_POST[id]");
    
} catch (Exception $e) {
    echo json_encode(array('success'=>0, 'msg'=>$e->getMessage()));
    $l = mysql_query("UNLOCK TABLES");
    exit;
}

$l = mysql_query("UNLOCK TABLES");
echo json_encode(array('success'=>1, 'objects'=>$objects));

?>