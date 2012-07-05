<?php   // handle a game response - eg. user answered correctly for trivia question
        // for trivia, if the user is hitting this script then s/he answered correctly

header("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
header("Cache-Control: no-store, no-cache, must-revalidate");
header("Cache-Control: post-check=0, pre-check=0", false);
header("Pragma: no-cache");

session_start();
require('config.php');

try {
    if(!isset($_POST['user_id']) || !isset($_POST['game_id']) || !is_numeric($_POST['game_id'])) throw new Exception("Bad data.");

    // get the game.
    $mstime = mstime();
    $q = mysql_query("SELECT * FROM games WHERE id = $_POST[game_id] AND (activated_time+wait_time+game_length_time+2000) > $mstime");
    if(mysql_errno()) throw new Exception("Game not found.");
    if(!mysql_num_rows($q)) throw new Exception("Game expired.");
    
    $game = mysql_fetch_assoc($q);
    
    // record score.
    $q = mysql_query("INSERT INTO points (points, user_id, round_id, game_id, created) VALUES ($game[points], $_POST[user_id], $_POST[round_id], $game[id], NOW())");
    if(mysql_errno()) throw new Exception(mysql_error());
    
    // update user's points
    $q = mysql_query("UPDATE users SET points = (points+$game[points]) WHERE id = $_POST[user_id]");
    if(mysql_errno()) throw new Exception(mysql_error());
    
} catch (Exception $e) {
    $friendly_msg = "There was a problem doing that. Everchat people have been notified.";
    echo json_encode(array('success'=>0, 'msg'=>$friendly_msg, 'system_msg'=>$e->getMessage(), 'mstime'=>$mstime));
    error_log($e->getMessage());
    exit;
}

echo json_encode(array('success'=>1));
