<?php

require('config.php');
require('image.php');

// form posted?
if(isset($_POST['new_trivia_question'])) {
    
    try {
        // -----------------------------------------------------------------------------------------
        // phase I - validate submitted data
        // -----------------------------------------------------------------------------------------
        
        if(!$_POST['question'] || strlen($_POST['question']) <= 5) throw new Exception("Question must be at least 5 characters long.");        

        if(!in_array($_POST['answer_type'], array('fill in the blank','multiple choice'))) throw new Exception("Answer type and answers are required.");
        if($_POST['answer_type'] == 'fill in the blank') {
            // account for blank fields
            $correctAnswers = array();
            foreach($_POST['correctAnswers'] AS $answer) {
                if(trim($answer)) $correctAnswers[] = $answer;
            }
            if(count($correctAnswers) == 0) throw new Exception("At least one answer is required.");
        }
        if($_POST['answer_type'] == 'multiple choice') {
            // account for blank fields
            $multipleChoiceAnswers = array();
            $i = 0;
            foreach($_POST['multipleChoiceAnswers'] AS $answer) {
                if(trim($answer)) {
                    $multipleChoiceAnswers[$i]['answer'] = $answer;
                    $multipleChoiceAnswers[$i]['correct'] = ($i == 0) ? true : false;
                    $i++;
                }
            }
            if(count($multipleChoiceAnswers) == 0) throw new Exception("At least one answer is required.");
        }

        if(!isset($_POST['question_display_time']) || !is_numeric($_POST['question_display_time'])) throw new Exception("Question length in seconds is required.");
        if(!isset($_POST['answer_display_time']) || !is_numeric($_POST['answer_display_time'])) throw new Exception("Answer display time is required.");

        // videos in a question or answer can be the only file attachment for the question or answer
        // in order to check them separately:
        // j+1 == 1 refers to a trivia_file_type_id of 1 which is a Question Component
        // j+1 == 2 refers to a trivia_file_type_id of 2 which is an Answer Component
        for($j = 0; $j < 2; $j++) {
            $k = 0;
            $has_flv = false;
            $i = 0;
            foreach($_FILES['files']['name'] AS $file_name) {
                if($file_name && isset($_POST['trivia_file_types'][$j]) && (int)$_POST['trivia_file_types'][$i] == ($j+1)) {
                    $k++;
                    $filename_last_index = strlen($_FILES['files']['name'][$i]) - 1;
                    if(in_array(substr($_FILES['files']['name'][$i], $filename_last_index-3), array('.flv'))) $has_flv = true;
                }
                $i++;
            }
            if($has_flv && $k > 1) throw new Exception('If the question uses a movie, it can be the only file attachment.');
        }

        // process files
        $i = 0;
        foreach($_FILES['files']['name'] AS $file_name) {
            // if there is a name, assume a file was supposed to be uploaded and validate everything else
            if($file_name) {
                $filename_last_index = strlen($_FILES['files']['name'][$i]) - 1;
                
                // A correct answer sound must be an mp3. Check extension.
                if($_POST['trivia_file_types'][$i] == '3' && !in_array(strtolower(substr($_FILES['files']['name'][$i], $filename_last_index-3)), array('.mp3'))) throw new Exception("Correct answer sound must be an mp3.");

                // General extension check.
                if(!in_array(strtolower(substr($_FILES['files']['name'][$i], $filename_last_index-3)), array('.jpg','.gif','.mp3','.flv'))) throw new Exception("Valid file extensions are jpg, gif, mp3, and flv.");

                if(!$_FILES['files']['tmp_name'][$i]) throw new Exception("File $i problem: temp file name not found.");
                if(!$_FILES['files']['size'][$i]) throw new Exception("File $i problem: size is 0.");
                if($_FILES['files']['size'][$i] > 2000000) throw new Exception("File $i problem: size is greater than 2MB.");
            }
            $i++;
        }

        // -----------------------------------------------------------------------------------------
        // phase II - create 'trivia' table record, 'files' table records, and move files
        // -----------------------------------------------------------------------------------------
        
        // create the record, attempt to move the temporary files
        $is_multiple_choice = ($_POST['answer_type'] == 'multiple choice') ? 1 : 0;
        $correctAnswersJSON = $multipleChoiceAnswersJSON = '';
        $word_count = 'NULL';
        if($is_multiple_choice) {
            $multipleChoiceAnswersJSON = mysql_real_escape_string(json_encode($multipleChoiceAnswers));
        } else {
            $correctAnswersJSON = mysql_real_escape_string(json_encode($correctAnswers));
            $word_count = (@$_POST['word_count_hint'] == 'on') ? $_POST['word_count'] : 'NULL';
        }
        $question = mysql_real_escape_string($_POST['question']);
        $question_display_time = $_POST['question_display_time']*1000;
        $answer_display_time = $_POST['answer_display_time']*1000;
        $game_length_time = $question_display_time + $answer_display_time;
        $extra_info = mysql_real_escape_string($_POST['extra_info']);
        if($_POST['credit_fb_id']) $credit_fb_id = (int)mysql_real_escape_string($_POST['credit_fb_id']);
        else $credit_fb_id = 'NULL';
        $q = mysql_query("INSERT INTO trivia (question, correctAnswers, multipleChoiceAnswers, isMultipleChoice, game_length_time, question_display_time, answer_display_time, extra_info, word_count, credit_fb_id) VALUES ('$question', '$correctAnswersJSON', '$multipleChoiceAnswersJSON', $is_multiple_choice, $game_length_time, $question_display_time, $answer_display_time, '$extra_info', $word_count, $credit_fb_id)");
        if(mysql_errno()) throw new Exception(mysql_error());
        if(!mysql_affected_rows($mysql)) throw new Exception("INSERT failed on 'trivia' table.");
        $trivia_id = mysql_insert_id();
        
        // add files to database and move from temporary locations to permanent locations
        $files_info = array();  // store progress information ]
        $i = 0;
        foreach($_FILES['files']['name'] AS $file_name) {
            // if there is a name, assume a file was supposed to be uploaded and validate everything else
            if($_FILES['files']['name'][$i]) {
                
                $files_info[$i] = array('filename'=>'', 'moved'=>false);    // initialize progress info about this file
                $filename_last_index = strlen($_FILES['files']['name'][$i]) - 1;
                $filename_ext = substr($_FILES['files']['name'][$i], $filename_last_index-3);
                $new_filename = 'trivia-' . $trivia_id . '-' . rand(0, 2000000000) . $filename_ext;
                
                // create database record in 'files' table
                // these file_type_id's probably shouldn't be hard coded like this. see 'file_types' table
                $file_type_id = 0;
                switch($filename_ext) {
                    case '.jpg':
                        $file_type_id = 2;
                        break;
                    case '.gif':
                        $file_type_id = 3;
                        break;
                    case '.mp3':
                        $file_type_id = 15;
                        break;
                    case '.flv':
                        $file_type_id = 16;
                        break;
                }

                if(in_array($file_type_id, array(2,3))) {
                    $image = new Image;
                    $image->open($_FILES['files']['tmp_name'][$i]);                
                    if($image->width > 550 || $image->height > 400) {
                        $image->resize_max(400, 550);   // max height, max width
                        $image->writejpeg($_FILES['files']['tmp_name'][$i], 75);
                        $_FILES['files']['size'][$i] = filesize($_FILES['files']['tmp_name'][$i]);
                    }                
                }
                
                if(!move_uploaded_file($_FILES['files']['tmp_name'][$i], TRIVIA_FILES_DIR . '/'  . $new_filename)) throw new Exception("Unable to move file from temporary location to permanent location. Filename:" . $new_filename);
                $files_info[$i] = array('filename'=>$new_filename, 'moved'=>true);
                
                $q = mysql_query("INSERT INTO files (file_name, file_size, file_type_id) VALUES ('$new_filename', {$_FILES['files']['size'][$i]}, $file_type_id)");
                if(mysql_errno() || !mysql_affected_rows($mysql)) throw new Exception("Unable to create file record in 'files' table.");
                $file_id = mysql_insert_id();

                // associate the trivia question with the file
                if(!$file_id || !$trivia_id) throw new Exception('Something is wrong with either trivia_id or file_id before associative record INSERT into \'trivia_files\'.');
                $caption = mysql_real_escape_string($_POST['file_captions'][$i]);
                $source = mysql_real_escape_string($_POST['file_sources'][$i]);
                $q = mysql_query("INSERT INTO trivia_files (file_id, trivia_id, trivia_file_type_id, caption, source) VALUES ($file_id, $trivia_id, {$_POST['trivia_file_types'][$i]}, '$caption', '$source')");
                if(mysql_errno() || !mysql_affected_rows($mysql)) throw new Exception("Unable to create record in 'trivia_files'.");
            }
            $i++;
        }

        // wow, success! 
        echo json_encode(array('success'=>1, 'msg'=>'Question submitted successfully.'));
        exit;

    // dang, problem.
    } catch (Exception $e) {
        echo json_encode(array('success'=>0, 'msg'=>'There was a problem: ' . $e->getMessage()));
        exit;
    }    
}

?>

<html>
<head>
	<script src="jquery-1.4.2.min.js" type="text/javascript"></script>
	<script src="jquery.form.js" type="text/javascript"></script>
    <style type="text/css">
        input { font-weight: bold; font-size:15px; margin-bottom:5px; }
        td { padding-bottom:10px; }
        td.submit_form { padding-right:20px; }
        .file { border: 1px dotted #cccccc; margin-bottom:5px; padding:7px; }
    </style>	
	<script type="text/javascript">
		$(document).ready(function() {
		
		    // answer type radio field - fill in the blank
	        $('#answer_type_blank').click(function(e) {
	            $('#multipleChoiceAnswers').hide();
	            $('#correctAnswers').slideDown();	            
	        });
	        
            // answer type radio field - multiple choice	        
	        $('#answer_type_choice').click(function(e) {
	            $('#correctAnswers').hide();
	            $('#multipleChoiceAnswers').slideDown();	            
	        });
	        
	        $('#word_count_hint').click(function(e) {
	            if($('#word_count_hint').is(':checked')) {
                    $('#word_count').attr('disabled', false);
	            } else {	            
                    $('#word_count').attr('disabled', true);
	            }
	        });
	        
			// jquery.form.js options for submitting the new trivia question form
			new_trivia_question_form_options = { 
				beforeSubmit: function(formData, jqForm, options) {
					$('#new_trivia_question_submit').attr('disabled', true);
				},
				success: function(data) {
					$('#new_trivia_question_submit').attr('disabled', false);
					if(data.success) {
						alert('Question submitted successfully.');
					    window.location = location.href;
					} else {
						alert(data.msg);
					}
				},  // post-submit callback 
				dataType: 'json',
				clearForm: false        // clear all form fields after successful submit 
			};
			$('#new_trivia_question').ajaxForm(new_trivia_question_form_options);	        
		});
		
		// add another fill-in-the-blank field
		function addCorrectAnswerField() {
		    var input = document.createElement("INPUT");
		    var br = document.createElement("BR");
		    $(input).attr('name', 'correctAnswers[]').attr('type','text').attr('size','40').css('font-weight','bold');
		    $('#correctAnswerFields').append(input).append(br);
		}

		// add another multiple choice field
		function addMultipleChoiceAnswerField() {
		    var input = document.createElement("INPUT");
		    var br = document.createElement("BR");
		    $(input).attr('name', 'multipleChoiceAnswers[]').attr('type','text').attr('size','40').css('font-weight','bold');
		    $('#multipleChoiceAnswerFields').append(input).append(br);
		}
		
		// add another file field
		function addFileField() {
		    var file_input = document.createElement("INPUT");
		    var br1 = document.createElement("BR");
		    $(file_input).attr('name', 'files[]').attr('type','file');

		    var select = document.createElement("SELECT");
		    $(select).attr('name','trivia_file_types[]');
		    
		    var option1 = document.createElement("OPTION");
            $(option1).attr('value', 1).append('Question Component');

		    var option2 = document.createElement("OPTION");
            $(option2).attr('value', 2).append('Answer Component');

		    var option2 = document.createElement("OPTION");
            $(option2).attr('value', 3).append('Correct Answer Sound');
            
            $(select).append(option1).append(option2).append(option3);  // put the select box together
            
		    var br2 = document.createElement("BR");
            var file_caption = document.createElement("INPUT");
            $(file_caption).attr('name','file_captions[]').attr('type','text').attr('size',30);
            
		    var br3 = document.createElement("BR");
            var file_source = document.createElement("INPUT");
            $(file_source).attr('name','file_sources[]').attr('type','text').attr('size',30);
            
            var file_div = document.createElement("DIV");
            $(file_div).attr('class','file').css('display', 'none');           
            $(file_div).append(select).append(' ').append(file_input).append(br1).append('Caption (optional):').append(file_caption).append(br2).append('Source (optional): ').append(file_source).append(br3);
            
            $('#files').append(file_div);  // add the select box and input field
            
            $(file_div).slideDown();
		}

    </script>    

</head>
<body>
    <div style="margin-bottom:10px"><img src="/everchat_m.png"></div>
    <p>Submit a question with optional image, mp3, or video. <a href="http://www.triviahalloffame.com/writeq.aspx">Writing Great Trivia Questions</a>.</p>
    <h3>New Trivia Question</h3>
    <?php
        if(isset($result_msg)) {
            echo '<div style="margin-bottom:10px">' . $result_msg . '</div>';
        }
    ?>    
    <form id="new_trivia_question" action="new_trivia_question.php" method="post" enctype="multipart/form-data">
        <table>
            <tr><td valign="top" class="submit_form">question</td> <td><textarea cols="60" name="question"></textarea></td></tr>
            <tr>
                <td valign="top" class="submit_form">answer(s)</td>
                <td valign="top">
                    <div style="margin-bottom:10px"><input type="radio" id="answer_type_choice" name="answer_type" value="multiple choice"> Multiple Choice <input type="radio" id="answer_type_blank" name="answer_type" value="fill in the blank"> Fill in the blank </div>
                    <div id="correctAnswers" style="display:none">
                        The first answer in this list will be displayed as the answer after time is up. Additional answers are likely misspellings or alternative responses that will count as correct. To check, everything is converted to lower case so you do not need to account for upper and lower case. Blank fields (below) are ignored.<br>                    
                        <div id="correctAnswerFields"> 
                            <input type="text" size="40" name="correctAnswers[]"> <input type="checkbox" id="word_count_hint" name="word_count_hint"> Show word count hint <select id="word_count" name="word_count" disabled="disabled"><option value="1">1</option><option value="2">2</option><option value="3">3</option><option value="4">4</option><option value="5">5</option><option value="6">6</option><option value="7">7</option><option value="8">8</option><option value="9">9</option><option value="10">10</option></select> <br>
                            <input type="text" size="40" name="correctAnswers[]"><br>
                            <input type="text" size="40" name="correctAnswers[]"><br>
                        </div>
                        <a href="#" onclick="addCorrectAnswerField(); return false;">Add Another</a>                        
                    </div>
                    <div id="multipleChoiceAnswers" style="display:none">                    
                        <div id="multipleChoiceAnswerFields"> Set the <b>first field</b> to the correct answer. Answers will be shuffled. Player will choose the answer by clicking. At least one answer is required. Blank fields are ignored.<br>
                            <input type="text" size="40" name="multipleChoiceAnswers[]"><br>
                            <input type="text" size="40" name="multipleChoiceAnswers[]"><br>
                            <input type="text" size="40" name="multipleChoiceAnswers[]"><br>
                            <input type="text" size="40" name="multipleChoiceAnswers[]"><br>
                        </div>
                        <a href="#" onclick="addMultipleChoiceAnswerField(); return false;">Add Another</a>
                    </div>
                </td>
            </tr>
            <tr>
                <td valign="top" class="submit_form">extra info</td>
                <td valign="top">
                    <div id="extra_info"> Extra information to be displayed along with the answer (optional)<br>
                        <textarea cols="60" name="extra_info"></textarea>
                    </div>
                </td>
            </tr>
            <tr>
                <td valign="top" class="submit_form">file(s)</td>
                <td>
                    Valid file extensions are jpg gif mp3 and flv. File size max is 2MB.
                    Question components display or play with the question while answer components
                    display along with the answer after time is up.
                    <br>
                    <div id="files">
                        <div class="file">
                            <select name="trivia_file_types[]">
                                <option value="1">Question Component</option>
                                <option value="2">Answer Component</option>
                                <option value="3">Correct Answer Sound</option>
                            </select>
                            <input type="file" name="files[]"> <br>
                            Caption (optional): <input type="text" size="30" name="file_captions[]"><br>
                            Source (optional): <input type="text" size="30" name="file_sources[]"><br>
                        </div>
                    </div>
                    <a href="#" onclick="addFileField(); return false;">Add Another</a>

                </td>
            </tr>
            <tr>
                <td valign="top" class="submit_form">timing</td>
                <td>
                    <table>
                        <tr>
                            <td>Question display:</td><td><input type="text" size="4" id="question_display_time" name="question_display_time" value="30"> seconds</td>
                        </tr>
                        <tr>
                            <td>Answer display:</td><td><input type="text" size="4" id="answer_display_time" name="answer_display_time" value="30"> seconds</td>
                        </tr>
                    </table>
                </td>
            </tr>
            <tr>
                <td></td>
                <td>
                    <input id="new_trivia_question_submit" type="submit" name="new_trivia_question" value="Submit Trivia Question">
                    <input id="credit_fb_id" type="hidden" name="credit_fb_id">
                    <input type="hidden" name="new_trivia_question" value="1">
                </td>
            </tr>    
        </table>
    </form>
    <div id="fb-root"></div>
    <script>
        window.fbAsyncInit = function() {
            FB.init({appId: '164947616866256', status: true, cookie: true, xfbml: true});

            FB.getLoginStatus(function(response) {
                if (response.session) {
                    // logged in and connected user, someone you know
                    FB.api('/me', function(response) {
                        $('#credit_fb_id').val(response.id);
                    });
                } else {
                    // no user session available, someone you dont know
                }
            });
        };
        (function() {
            var e = document.createElement('script'); e.async = true;
            e.src = document.location.protocol + '//connect.facebook.net/en_US/all.js';
            document.getElementById('fb-root').appendChild(e);
        }());
    </script>    
</body>
</html>