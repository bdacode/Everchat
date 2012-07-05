<?php
    session_start(); 
    $_SESSION['userID'] = 1;    // fake login for testing

    if(isset($_GET['logout'])) {
        session_destroy();
        session_start();
    }
    require('config.php');

    // get wall
    $got_wall = false;
    $url_name = '';
    
    // play is set if the user just wants to enter the game
    if(isset($_GET['play'])) {
    
        // select the wall with the most number of members that has less than 20 active webcams
        // this algorithm attempts to keep existing walls full at the expense of new walls
        // a poll will be necessary for users in walls that have less than 5 people. alternatively
        // a "Join Another Wall" button can try the query again. 
        $q = mysql_query("SELECT id FROM walls WHERE num_active_webcams < 20 AND num_members > 0 AND num_members < 50 ORDER BY num_members DESC LIMIT 1");
    
        // potential outcomes: 1 - record found. pass wall_id. 2 - no record found. create wall and pass that id. 
        if(mysql_num_rows($q)) {    // result. use this wall.
            
        } else {    // no result. create wall.
        
        }
        
    } else {    // otherwise the user might be requesting a specific wall
    
        if(isset($_GET['q'])) {
//            $url_name = substr($_GET['q'], 1, strlen($_GET['q']));  // chop off forward slash
              $url_name = $_GET['q'];
        } else {
            $url_name = explode('.', $_SERVER['HTTP_HOST']);
            if(count($url_name) > 2) $url_name = $url_name[0];
            else $url_name = '';
        }
    
        // determine wall_id
        if($url_name) {
            $url_name = mysql_real_escape_string($url_name);
            $q = mysql_query("SELECT * FROM walls WHERE url_name = '$url_name'");
            if(mysql_num_rows($q)) {
                $wall = mysql_fetch_assoc($q);
                $got_wall = true;
            }
        }
    }
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:fb="http://www.facebook.com/2008/fbml">
	<head>
        <title>Everchat</title>
        
        <meta property="og:title" content="Everchat"/>
        <meta property="og:type" content="website"/>
        <meta property="og:url" content="<?php echo SITE_URL; ?>"/>
        <meta property="og:image" content="<?php echo SITE_URL; ?>/title.png"/>
        <meta property="og:site_name" content="Everchat"/>
        <meta property="fb:app_id" content="164947616866256"/>
        <meta property="og:description" content="Everchat is a Facebook-only webcam and trivia hangout"/>
        
        <meta property="description" content="Everchat is a Facebook-only webcam and trivia hangout"/>
                   
        <style type="text/css" media="screen"> 
			html, body	{ height:100%; }
			body { margin:0; padding:0; overflow:auto; text-align:center; background-color: #ffffff; }   
			object:focus { outline:none; }
        </style>
        
	 	<!-- Include support librarys first -->
		<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/swfobject/2.2/swfobject.js"></script>
		<script type="text/javascript" src="http://connect.facebook.net/en_US/all.js"></script>
		
		<!-- Include FBJSBridge to allow for SWF to Facebook communication. -->
		<script type="text/javascript" src="FBJSBridge.js"></script>
		
		<script type="text/javascript">
			function embedPlayer() {
                <?php
                    $flashvars = array();
                    $flashvars['sessionid'] = session_id();
                    if($got_wall) $flashvars['wall_id'] = $wall['id'];
                    $flashvars = json_encode($flashvars);
                ?>
                var flashvars = <?php echo $flashvars; ?>;
                var params = {'quality':'high', 'bgcolor':'#ffffff', 'allowscriptaccess':'sameDomain', 'allowfullscreen':'true' };
				embedSWF("everchat.swf", "flashContent", "100%", "100%", "10.1", "playerProductInstall.swf", flashvars, params);
			}
			//Redirect for authorization for application loaded in an iFrame on Facebook.com 
			function redirect(id,perms,uri) {
				var params = window.location.toString().slice(window.location.toString().indexOf('?'));
				top.location = 'https://graph.facebook.com/oauth/authorize?client_id='+id+'&scope='+perms+'&redirect_uri='+uri+params;				 
			}
			embedPlayer();
		</script>

  </head>
  <body>
    <div id="fb-root"></div>
    <div id="flashContent">
        <h1>Everchat requires Flash 10.1.</h1>
        <p><a href="http://www.adobe.com/go/getflashplayer"><img src="http://www.adobe.com/images/shared/download_buttons/get_flash_player.gif" alt="Get Adobe Flash player" /></a></p>
    </div>
  </body></html>