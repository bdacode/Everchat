<?php

// script uploads a banner file, returning the temporary file name

session_start();

require('config.php');

$objects = array(); // return objects to be replicated in JSON format

try {

    // require all data
    if(!isset($_POST['id']) || !is_numeric($_POST['id']) || !isset($_FILES['Filedata']['size'])) throw new Exception('Required data not found.');
    if($_FILES['Filedata']['size'] > 100000) throw new Exception('Max file size is 100k.');
    if(!preg_match('/^.*\.(jpg|jpeg|png|gif)$/i', $_FILES['Filedata']['name'])) throw new Exception("Valid file types are JPEG, PNG, and GIF.");

    // determine file type
    if(preg_match('/^.*\.(jpg|jpeg)$/i', $_FILES['Filedata']['name'])) {
        $file_type_id = 2;
    } else if(preg_match('/^.*\.(png)$/i', $_FILES['Filedata']['name'])) {
        $file_type_id = 1;
    } else if(preg_match('/^.*\.(gif)$/i', $_FILES['Filedata']['name'])) {
        $file_type_id = 3;    
    }
    $file_name = 'tmp_' . rand(0,1000000000);
    $q = mysql_query("INSERT INTO files (file_type_id, file_size, file_name) VALUES ($file_type_id, {$_FILES[Filedata][size]}, '$file_name')");
    if(mysql_errno()) throw new Exception(mysql_error());
    $file_id = mysql_insert_id();
    
} catch (Exception $e) {
    echo json_encode(array('success'=>0, 'msg'=>$e->getMessage()));
    exit;
}

echo json_encode(array('success'=>1, 'tmp_banner_filename'=>$file_name, 'new_banner_file_id'=>$file_id, 'new_banner_file_type_id'=>$file_type_id));