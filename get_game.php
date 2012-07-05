<?php   // get the current/next game for a particular wall.
        // script always returns an array of objects that will be added to the client's
        // object list
        // 'start game' object {'type':'start game', 'game_object_id':555, 'activation_time':388383838}
/* game creation rewrite    
    . get 4 games
    . if there are less than 4, create a round and start over
    . if there are greater than 4, check the first game for expiration
        . expired: start next game, return three
        . current: return all
*/

require_once('functions.php');
nocache();
session_start();
require('config.php');

$objects = array();     // returned in JSON format

try {
    if(!isset($_POST['wall_id']) || (!isset($_POST['get']) && !isset($_POST['answer']))) throw new Exception("Bad data.");
    
    if(isset($_POST['get'])) {  // request current game being played
        
        // lock the tables. this should be preventing access to walls and games and writes to rounds
        $l = mysql_query("LOCK TABLES walls WRITE, games WRITE, rounds WRITE, points READ, users READ, trivia READ, trivia AS trivia2 READ, files READ, file_types READ, trivia_files READ");
        if(mysql_errno()) throw new Exception(mysql_error());

        // get the starting object index
        $o = mysql_query("SELECT last_object_id FROM walls WHERE id = $_POST[wall_id]");
        $o = mysql_fetch_assoc($o);
        $object_id = (int)$o['last_object_id'];
        $object_id++;
        
        // get 4 games
        $games = getGames(array('wall_id'=>$_POST['wall_id']));
        if(count($games) < 4) {
            createRound(array('wall_id'=>$_POST['wall_id'], 'trivia_testing_mode'=>(isset($_POST['trivia_testing_mode'])) ), $object_id);
            $games = getGames(array('wall_id'=>$_POST['wall_id']));
            if(count($games) < 4) throw new Exception(ERROR_6, 6);
        } 
        $objects = $games + $objects;

$z = 0;
        // determine whether a game needs to be started
        if( (int)$games[key($games)]['activated_time'] == 0 ) {
$z = 1;
            $objects[$object_id] = startGame($games[key($games)]['id']);
            $object_id++;
        } else if( (mstime() - $games[key($games)]['activated_time']) > ($games[key($games)]['wait_time'] + $games[key($games)]['game_length_time']) ) {
$z = 2;
            $objects[$object_id] = startGame($games[key($games)]['next_game_id']);
            $object_id++;
        } else {
$z = 3;
            $objects[$games[key($games)]['start_object_id']] = $games[key($games)];
            $objects[$games[key($games)]['start_object_id']]['type'] = 'current game';    // client will attempt to play the game            
        }

        // get the round data
        $r = getRound(array('wall_id'=>$_POST['wall_id']));   // get post-game round status if it was requested

        if($r != false) {
            $objects[$object_id] = $r;
            $object_id++;
        }        
    }
        
} catch (Exception $e) {
    $friendly_msg = 'Something went wrong. Everchat people have been notified.';
    echo json_encode(array('success'=>0, 'msg'=>$friendly_msg, 'system_msg'=>$e->getMessage()));
    error_log($e->getMessage());
    unlockTables();
    exit;
}

// move the object index for this wall
$u = mysql_query("UPDATE walls SET last_object_id = $object_id WHERE id = $_POST[wall_id]");

unlockTables();

echo json_encode(array('success'=>1, 'objects'=>$objects, 'z'=>$z));

// activates the next game using a game_id and returns a 'start game' object type
function startGame($id) {
    if(!$id) throw new Exception('game_id is required to start');
    $return_me = array();
    $mstime = $return_me['activated_time'] = mstime();     // time in milliseconds
    $q = mysql_query("UPDATE games SET activated_time = $mstime WHERE id = $id");
    if(!$q) throw new Exception('game activation failed');
    $g = mysql_query("SELECT start_object_id, wall_id FROM games WHERE id = $id");
    if(!$q) throw new Exception('game SELECT after activation failed');
    $g = mysql_fetch_assoc($g);

    // this is so joining chat users will start wanted objects at the right place
    $q = mysql_query("UPDATE walls SET last_started_game_object_id = $g[start_object_id] WHERE id = $g[wall_id]");
    if(!$q) throw new Exception('UPDATE walls last_started_game_object_id failed');

    $return_me['game_to_start_object_id'] = (int)$g['start_object_id'];  // object id - unique to wall
    $return_me['type'] = 'start game';      // object type
    return $return_me;
}

// return an array of round data given an id or wall_id
function getRound($opts) {

    $round = array('type'=>'round','table'=>array());
    
    if(isset($opts['wall_id']) && is_numeric($opts['wall_id'])) {
        $q = mysql_query("SELECT round_id, round_num FROM games WHERE wall_id = $opts[wall_id] AND activated_time > 0 ORDER BY id DESC LIMIT 1");
        $current_round = mysql_fetch_assoc($q);
        $opts['id'] = $current_round['round_id'];
        
        $round['id'] = $opts['id'];        
        $round['num_games_played'] = $round['last_round_num'] = $current_round['round_num'];        
    }
    
    if(isset($opts['id']) && is_numeric($opts['id'])) {
        $entry = array();
        $r = mysql_query("SELECT sum(points.points) AS points, users.username AS username FROM points,users WHERE points.round_id = $opts[id] AND user_id = users.id GROUP BY users.username ORDER BY points DESC");
        while($entry = mysql_fetch_assoc($r)) {
            $round['table'][] = $entry;
        }

        return $round;
    }
    
    return array('id'=>0);
}

// return games using wall_id and optional size
function getGames($opts=array()) {

    $games = array();
    $num = 3;           // number of non-activated games to get

    try {
        // require integer wall_id        
        if( !isset($opts['wall_id']) || !is_numeric($opts['wall_id']) ) {
            $opts['wall_id'] = (int)$opts['wall_id'];
            throw new Exception(ERROR_4, 4);
        }

        // get the latest activated game
        $q = mysql_query("SELECT * FROM games WHERE wall_id = $opts[wall_id] AND activated_time > 0 ORDER BY id DESC LIMIT 1");
        if(mysql_errno()) throw new Exception(ERROR_5, 5);
        if(mysql_num_rows($q)) {
            $game = mysql_fetch_assoc($q);
            $games[$game['start_object_id']] = processGameData($game);
        } else {
            $num = 4;
        }
        
        // get the next three
        $q = mysql_query("SELECT * FROM games WHERE wall_id = $opts[wall_id] AND activated_time = 0 ORDER BY id ASC LIMIT $num");
        if(mysql_errno()) throw new Exception(ERROR_5, 5);
        while($game = mysql_fetch_assoc($q)) {
            $games[$game['start_object_id']] = processGameData($game);
        }

    } catch (Exception $e) {
        throw new Exception($e->getMessage());
    }

    return $games;
}

// convert 'data' field to json
function processGameData($game) {
        $game['data'] = json_decode(utf8_encode($game['data']));   // decode the JSON
        $game['type'] = 'game';
        return $game;
}

// create a round
function createRound($opts=array(), &$object_id) {
    try {

        if( !isset($opts['wall_id']) || !is_numeric($opts['wall_id']) ) {
            $opts['wall_id'] = (int)$opts['wall_id'];
            throw new Exception('createRound() requires wall_id');
        }

        $game_definition_id = 1;    // force trivia for testing
        $next_game_id = 0;          // this is required
        $last_game_id = 0;          // last game_id of last round going into the function call
        $games_per_round = 10;      // might be wall based variable in future
        $chunk_size = P2P_CHUNK_SIZE;        // p2p file chunk size (must match the number that is in the Flash app)
        
        // psuedo code for creating a round:
        // . create a rounds table record and get the round_id
        // . for now, set game_definition_id to 1 and create trivia games
        //      or - randomize game_definition_id 
        // . 
        
        $r = mysql_query("INSERT INTO rounds (wall_id) VALUES ($_POST[wall_id]) ");
        if(mysql_errno()) throw new Exception(mysql_error());
        $round_id = mysql_insert_id();

        for($i = 0; $i < $games_per_round; $i++) {
        
            if ($game_definition_id == 1) {
            
            /* psuedo code for getting the greater of wait_time or last trivia game's answer_delay_time
                - if this is the first game in the round

                rewrite of game timer stuff
                - total time is the time from START to END to WAIT to START, etc
                - trivia-related timers should be specific to trivia games
                   * game_length + answer_length = total_length
                   * startGame() --> playGame() --> trivia_showQuestion() --> trivia_showAnswer() --> stopGame()
                - startReceivedGame() could have a hard-coded wait_time of 15 seconds or so
                - then, the game itself can use countdownBar and countdownBarContainer for game related timers
                - startReceivedGame() will know in advance when to run playGame() and also stopGame()
            */
            
                $t = array();                   // the trivia question
                $wait_time = 20000;             // wait time in ms before game starts
                                
                // get random trivia question
                $approved_value = 1;
                // unapproved question review mode (admin function)?
                if(isset($opts['trivia_testing_mode']) && $opts['trivia_testing_mode']) $approved_value = 0;
                $trivia_count = mysql_query("SELECT COUNT(*) AS trivia_count FROM trivia WHERE approved = $approved_value");
                if(mysql_errno()) throw new Exception(mysql_error());
                $trivia_count = mysql_fetch_assoc($trivia_count);
                $rand = rand(0, $trivia_count['trivia_count']-1);
                $t = mysql_query("SELECT * FROM trivia WHERE approved = $approved_value LIMIT $rand,1");
                if(mysql_errno()) throw new Exception(mysql_error());
                $t = mysql_fetch_assoc($t);
                $t['correctAnswers'] = json_decode(utf8_encode($t['correctAnswers']));
                $t['multipleChoiceAnswers'] = json_decode(utf8_encode($t['multipleChoiceAnswers']));
                $t['question'] = utf8_encode($t['question']);
                $t['extra_info'] = utf8_encode($t['extra_info']);
                $t['question_display_time'] = utf8_encode($t['question_display_time']);
                $t['answer_display_time'] = utf8_encode($t['answer_display_time']);
        
                // get files
                $f = mysql_query("SELECT files.file_name AS file_name, files.file_size AS file_size, file_types.ext AS file_type, trivia_files.trivia_file_type_id AS trivia_file_type_id FROM files, trivia_files, file_types WHERE trivia_files.trivia_id = $t[id] AND files.id = trivia_files.file_id AND files.file_type_id = file_types.id");
                if(mysql_errno()) throw new Exception(mysql_error());

                $t['num_files'] = mysql_num_rows($f);
                $t['files_meta'] = array();
                $total_file_size = 0;       // bytes
                $game_start_object_id = $object_id;
                if($t['num_files'] > 0) {
                    $object_id++;
                    $file_num = 0;
                    while($file = mysql_fetch_assoc($f)) {
                        $file['file_num'] = $file_num; $file_num++;
                        $file['start_object_id'] = (int)$object_id;  // start object_id of the file
                        $file['num_chunks'] = floor($file['file_size']/$chunk_size)+1;  // will be at least 1
                        $file['end_object_id'] = (int)($object_id + ($file['num_chunks']-1));
                        $file['url'] = SITE_URL . '/files/' . $file['file_name'];
                        $object_id = (int)($file['end_object_id']+1);
                        $t['files_meta'][] = $file;              
                        $total_file_size += (int)$file['file_size'];
                    }
                    $object_id--;
        
                    // calculate the number of seconds to count down before the game starts playing
                    // this uses an automatic algorithm with 45 seconds for every 1MB of files
                    /*
                    if($total_file_size > 0) {
                        $potential_wait_time = (int)(($total_file_size / 1000000) * 30000); // 45 seconds in ms
                        $wait_time = ($potential_wait_time > 20000) ? $potential_wait_time : $wait_time;
                    }
                    */
                }
        
                // put the game in the database
                $json_data = mysql_real_escape_string(json_encode($t));     // escape
            }        

            $round_num = $i+1;
            $q = mysql_query("INSERT INTO games (start_object_id, end_object_id, data, points, wall_id, next_game_id, wait_time, game_definition_id, game_length_time, round_id, round_num) VALUES ($game_start_object_id, $object_id, '$json_data', $t[points], $opts[wall_id], $next_game_id, $wait_time, $game_definition_id, $t[game_length_time], $round_id, $round_num)");
            if(mysql_errno()) throw new Exception(mysql_error());
            $new_game_id = mysql_insert_id();            
            $object_id++;

            // if there is a current game, set the next id
            if($i > 0) {
                $last_game_id = $new_game_id - 1;
            } else {    // get the game_id from the last round
                $l = mysql_query("SELECT id FROM games WHERE round_id < $round_id AND wall_id = $opts[wall_id] ORDER BY id DESC LIMIT 1");
                if(mysql_errno()) throw new Exception(mysql_error());
                $last_game_id = mysql_fetch_assoc($l);
                $last_game_id = $last_game_id['id'];
            }
            if($last_game_id) {
                $q = mysql_query("UPDATE games SET next_game_id = $new_game_id WHERE id = $last_game_id");
                if(mysql_errno()) throw new Exception(mysql_error());
            }
        }
        return true;

    } catch (Exception $e) {
        throw new Exception($e->getMessage());
    }
}

function unlockTables() {
    $l = mysql_query("UNLOCK TABLES");
}

?>