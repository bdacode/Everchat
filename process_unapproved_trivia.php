<?php   // process unapproved trivia question

header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
header("Cache-Control: no-store, no-cache, must-revalidate");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

require('config.php');

$objects = array();     // returned in JSON format

try {
    if(!isset($_POST['trivia_id']) || !is_numeric($_POST['trivia_id']) || !isset($_POST['action']) || ($_POST['action'] != 'Approve' && $_POST['action'] != 'Deny')) throw new Exception("Bad data.");

    if($_POST['action'] == 'Deny') {
        // get any files
        $q = mysql_query("SELECT * FROM files, trivia_files WHERE files.id = trivia_files.file_id AND trivia_files.trivia_id = $_POST[trivia_id]");
        if(mysql_errno()) throw new Exception('Problem selecting file records.');
        if(mysql_num_rows($q)) {    // there are files
            while($file = mysql_fetch_assoc($q)) {
                // delete the file on the disk
                if(!unlink(LOCAL_FILES_DIR . '/' . $file['file_name'])) throw new Exception("Unable to delete file from disk.");
                
                // delete file record
                $d = mysql_query("DELETE FROM files WHERE id = $file[id]");
                if(mysql_errno()) throw new Exception("Problem deleting records from 'files'.");
            }
            
            // delete association
            $da = mysql_query("DELETE FROM trivia_files WHERE trivia_id = $_POST[trivia_id]");
            if(mysql_errno()) throw new Exception("Problem deleting records from 'trivia_files'.");
        }

        $q = mysql_query("DELETE FROM trivia WHERE id = $_POST[trivia_id]");
        if(mysql_errno()) throw new Exception("Problem deleting records from 'trivia'.");

    } else if($_POST['action'] == 'Approve') {
        $q = mysql_query("UPDATE trivia SET approved = 1 WHERE id = $_POST[trivia_id]");
        if(mysql_errno()) throw new Exception('Unable to approve the trivia question. ' . mysql_error());
    }
    
} catch (Exception $e) {
    echo json_encode(array('success'=>0, 'msg'=>$e->getMessage()));
    exit;
}

echo json_encode(array('success'=>1));

?>