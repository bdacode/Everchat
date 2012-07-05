package
{
	import com.adobe.serialization.json.JSON;
	import com.adobe.utils.StringUtil;
	
	import creacog.spark.components.ResizeableTitleWindow;
	
	import flash.display.Bitmap;
	import flash.display.GradientType;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.net.NetStreamAppendBytesAction;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.utils.Timer;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import flashx.textLayout.conversion.TextConverter;
	
	import mx.controls.Alert;
	import mx.core.SoundAsset;
	import mx.core.UIComponent;
	import mx.events.CloseEvent;
	import mx.events.EffectEvent;
	import mx.events.FlexEvent;
	import mx.graphics.SolidColor;
	import mx.managers.PopUpManager;
	import mx.utils.ObjectUtil;
	import mx.utils.object_proxy;
	
	import org.audiofx.mp3.MP3FileReferenceLoader;
	import org.audiofx.mp3.MP3SoundEvent;
	
	import spark.components.Button;
	import spark.components.CheckBox;
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.HSlider;
	import spark.components.Label;
	import spark.components.Panel;
	import spark.components.RichEditableText;
	import spark.components.RichText;
	import spark.components.Scroller;
	import spark.components.TextInput;
	import spark.components.TitleWindow;
	import spark.components.VGroup;
	import spark.effects.Animate;
	import spark.effects.animation.MotionPath;
	import spark.effects.animation.SimpleMotionPath;
	import spark.primitives.Rect;
	import spark.utils.TextFlowUtil;
	
	public class GameWindow extends ResizeableTitleWindow
	{
		private var room:Wall;
		
		public var gameContainer:GameContainer = new GameContainer;
		public var gameContent:VGroup = new VGroup;			// live updating list of people who win a game
		public var gameWinnersList:VGroup = new VGroup;		// live updating list of people who win a game
		private var gameWinnersGroup:Group = new Group;			// contain gameWinnersList and a background color
		//		private var countDownDisplay:Label = new Label;
		private var countdownBarContainer:Group = new Group;		// countdownBar is always added to this
		private var countdownBar:CountdownBar = new CountdownBar;
		private var countDownTime:Number = new Number;
		public var game_on:int = 0;			// 1=wall is playing games 0=wall is not playing games
		public var game_in_intermission:Boolean = false;
		public var game:Game;				// generic storage for a retrieved game
		private var game_time_offset:int = 0; 
		private var starting_game:int = 0;	// used only if admin starts a game	
		public var roundData:VGroup = new VGroup;
		private var intermissionMsgGroup:VGroup = new VGroup;
		private var intermissionMsg:RichEditableText = new RichEditableText;
		private var triviaGameAnswerResponse:VGroup;					// player sees this after answering a trivia question		
		private var emoticons:Emoticons = new Emoticons;
		public var window_open:Boolean = false;
		private var roundResultScreen:VGroup;
		private var gameScrollerContainer:Group = new Group;
		private var gameScroller:Scroller = new Scroller;

		// timers
		private var getGameFailsafeTimer:uint;				// gets next game in case object is not propogated to user in time
		private var stopGameTimer:uint;						// ends a game after its time limit has been reached
		private var playGameTimer:uint;						// triggers the next game start
//		private var playGameGetTimer:uint;					// marks beginning of playGame() call
		private var gameCountDownTimer:uint;				// counts down to the next game start
		private var gameCountDownGetTimer:Number;			// getTimer() when countdown starts
//		private var triviaQuestionCountDownTimer:uint;		// counts down to the end of the trivia question display
		private var triviaQuestionCountDownGetTimer:Number;	// getTimer() when trivia question is first displayed
		private var triviaQuestionCountDownTime:Number;
		private var triviaAnswerCountdownTimer:uint;		// timer counts down to trivia_showAnswer() call
		public var seedTimer:uint;
//		public var joinGameTimer:uint;
		public var serverTimeOffset:int = 0;		// track server milliseconds since Jan 1 1970 minus local milliseconds since Jan 1 1970
		private var potentialGameDelayTimer:uint;	// too long to get next game...show potential delay message (during intermission)
		private var officialGameDelayTimer:uint;	// officially delayed - way too long to get next game
		public var seedGameTimer:uint;				// runs a determineWhetherSeeder timer to ensure game restarts after a game delay (server down, etc)

		// net
		private var loader:URLLoader;
		private var loaders:Object = new Object;
		
		// trivia
		private var triviaAnswerBox:TextInput = new TextInput;
		private var triviaQuestion:RichText = new RichText;
		private var triviaGameResult:RichText = new RichText;
		private var triviaSound:Sound = new Sound;
		private var triviaSoundChannel:SoundChannel = new SoundChannel;
		private var triviaVideoNetStream:NetStream;
		private var triviaVideoContainer:UIComponent;
		private var triviaVideo:TriviaVideo;		// has a file member containing the video file - this was easier than extending NetStream
		private var trivia_testing_room_name:String = 'secret trivia testing room';	// in this room unapproved questions can be approved
		private var trivia_testing_buttons:HGroup;	// contains approve and delete buttons
		private var notReadyMsg:RichText = new RichText;
		private var triviaGameResponsePulse:Animate;
		private var chosenMultipleChoice:Object;	// when a multiple choice answer is chosen, it is stored here
		private var multipleChoiceGroup:VGroup;		// contains horizontal groups of clickable multiple choice labels
//		[Embed(source="silkscreen2.ttf", fontFamily="silkscreen2", fontWeight= "normal", fontStyle = "normal", mimeType="application/x-font-truetype")]
//		private var fontSilkscreen:Class;
		private var triviaAnswerMedia:Group;
		private var triviaQuestionImageContainer:UIComponent;
		private var triviaQuestionImage:Bitmap;
		private var triviaAnswerScreen:VGroup;
		private var triviaVolumeSlider:HSlider = new HSlider;
				
		// other
		private var trivia_id_to_process:uint;		// stores a trivia_id to process (only in special testing/review room)
		
		// sounds
		private var triviaSounds:TriviaSounds = new TriviaSounds;
		
		public function GameWindow(room:Wall)
		{
			super();
			this.room = room;
			this.game = new Game(room);
			this.setStyle('backgroundAlpha', 0.80);
		}
		
		// initialize game window
		// 
		//  gameContainer
		//  --------------------------------------
		//  |                  |                 |
		//	| gameContent      | gameWinnersList |
		// 	--------------------------------------
		public function init():void {
			this.gameContent.removeAllElements();
			this.addEventListener(Event.RESIZE, this.resizeGameWindow);			
			this.x				= 150;
			this.y				= 100;
			this.width			= 750;
			this.minWidth		= 250;
			this.height			= 475;
			this.minHeight		= 250;
			this.title			= "Game";   
			this.setStyle('cornerRadius', '7');
			this.setStyle('borderAlpha', '0.85');
			this.addEventListener(CloseEvent.CLOSE, closeGameWindow);
			this.addEventListener(MouseEvent.CLICK, focusGameWindow);
						
			this.triviaQuestion.percentWidth = this.triviaGameResult.percentWidth = this.notReadyMsg.percentWidth = 100;
			this.triviaQuestion.setStyle('fontSize', 15);
			this.triviaQuestion.setStyle('fontFamily', "Lucida Sans Unicode");
			this.triviaAnswerBox.setStyle('textAlign', 'center');
			
			this.triviaVolumeSlider.addEventListener(Event.CHANGE, trivia_changeVolume);
			this.triviaVolumeSlider.minimum = 0;
			this.triviaVolumeSlider.maximum = 100;
			this.triviaVolumeSlider.value = 50;
			
			this.intermissionMsg.selectable = false;
			this.intermissionMsg.editable = false;
			
			this.countdownBarContainer.percentWidth = 100;
			this.countdownBarContainer.height = 20;
						
			// this is a real-time winners list
			this.gameWinnersList.percentWidth = 100;
			this.gameWinnersList.clipAndEnableScrolling = true;
			this.gameWinnersList.paddingBottom = this.gameWinnersList.paddingTop = this.gameWinnersList.paddingLeft = this.gameWinnersList.paddingRight = 10;	
			var gameWinnersGroupBG:Rect = new Rect;
			gameWinnersGroupBG.percentHeight = gameWinnersGroupBG.percentWidth = 100;
			gameWinnersGroupBG.alpha = 0.85;
			gameWinnersGroupBG.radiusX = gameWinnersGroupBG.radiusY = 10;
			gameWinnersGroup.width = 130;
			gameWinnersGroup.right = 15;
			gameWinnersGroup.top = 15;
			gameWinnersGroup.setStyle('cornerRadius', 10);
			gameWinnersGroupBG.fill = new SolidColor(0xFFFFFF);
			gameWinnersGroup.addElement(gameWinnersGroupBG);
			gameWinnersGroup.addElement(this.gameWinnersList);
			this.gameContainer.gameWinnersGroup = gameWinnersGroup;
			this.gameContainer.addElement(gameWinnersGroup);
			this.gameContent.gap = 10;
			this.gameContent.paddingBottom = this.gameContent.paddingTop = this.gameContent.paddingLeft = this.gameContent.paddingRight = 10;
			
			this.gameContainer.addElement(gameContent);
			this.addElement(gameContainer);
			
			this.resizeGameWindow(new Event(Event.COMPLETE));
			this.showGameIntermission();
			
		}
		
		private function focusGameWindow(e:Event):void {
			if(this.game.game_definition_id == 1 && this.gameContent.contains(triviaAnswerBox) && triviaAnswerBox.enabled) this.triviaAnswerBox.setFocus();
			else this.setFocus();
		}
		
		private function closeGameWindow(e:CloseEvent):void {
			PopUpManager.removePopUp(this);
			triviaSoundChannel.stop();
			if(triviaVideoNetStream != null) triviaVideoNetStream.play(null);
			this.window_open = false;
		}
		
		public function showGameWindow(e:MouseEvent):void {
			PopUpManager.addPopUp(this, room.mainLayer, false);
			this.focusGameWindow(e);
			this.window_open = true;
		}
		
		// Turn games on for this user.
		private function resizeGameWindow(e:Event):void {
			if(this.numElements > 0) {
				this.gameContainer.width = this.width - 2;
				this.gameContainer.height = this.height - 33;	
				// the 15 is gameWinnersGroup.right or distance from right boundary
				this.gameContent.width = this.width - gameWinnersGroup.width - 15;
				if(triviaQuestionImageContainer != null && this.gameContent.contains(triviaQuestionImage)) if(triviaQuestionImage.width < (gameContent.width-this.gameContent.paddingLeft-this.gameContent.paddingRight)) triviaQuestionImage.x = ((gameContent.width-this.gameContent.paddingLeft-this.gameContent.paddingRight) / 2) - (triviaQuestionImage.width / 2);	// center the image
			}
		}
		
		// the time on the server will be different than the time in the client, even adjusted
		// for time zones. therefore, keep a variable that represents the difference between
		// the server's milliseconds since Jan 1 1970 and the client's (Flash) milliseconds since
		// Jan 1 1970. this process must be successful or the game should be halted. 
		public function getServerTime():void {
			var variables:URLVariables = new URLVariables;
			var request:URLRequest = new URLRequest(this.room.CONFIG.SITE_URL + "/time.php");
			request.method = URLRequestMethod.GET;
			loaders['getServerTime'] = new URLLoader;
			loaders['getServerTime'].addEventListener(Event.COMPLETE, handleGetServerTime);
			//loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			try {
				loaders['getServerTime'].load(request);
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}	
		}
		
		// the server is returning its milliseconds since Jan 1 1970. 
		// serverTimeOffset = server ms since 1/1/1970 minus local ms since 1/1/1970
		private function handleGetServerTime(e:Event):void {
			try {				
				if(isNaN(Number(loaders['getServerTime'].data))) throw Error('Expected milliseconds since Jan 1 1970');
				var d:Date = new Date();
				serverTimeOffset = int(loaders['getServerTime'].data) - d.getTime();
				trace('serverTimeOffset:'+serverTimeOffset);
			} catch (e:Error) {
				trace("Could not get the server time offset. ");
			}	
		}
		
		// this is what happens between games
		private function showGameIntermission():void {
			this.gameContent.removeAllElements();
			this.countdownBarContainer.removeAllElements();
			
			clearGameDelayTimers();
			startGameDelayTimers();
			this.game_in_intermission = true;
			intermissionMsgGroup = new VGroup;
			intermissionMsgGroup.percentWidth = 100;
			intermissionMsgGroup.gap = 10;
			intermissionMsgGroup.paddingBottom = 10;
			intermissionMsg = new RichEditableText;
			intermissionMsg.editable = false;
			intermissionMsg.selectable = false;
			intermissionMsg.percentWidth = 100;
			intermissionMsg.setStyle('textAlign', 'center');
			intermissionMsgGroup.addElement(intermissionMsg);
			intermissionMsg.textFlow = TextFlowUtil.importFromString("The next game is on the way.");				
			this.gameContent.addElement(countdownBarContainer);
			this.gameContent.addElement(intermissionMsgGroup);
		}
		
		public function startGame(object_id:int):void {

			// trivia games might explicitly override the intermission time (wait_time) because an answer
			// needs more time to display - usually a longer video or audio clip
			this.game = new Game(this.room);
			this.game.initializeFromP2PObject(this.room.objects[object_id]);

			// determine offset from now to time to start
			var d:Date = new Date();
			var timeToPlay:Number = (Number(this.game.activated_time) + this.game.wait_time) - (d.getTime() + serverTimeOffset);
			
			// clear existing timers if they are still running. these are about to be created again.
			clearGameTimers();
			
			if(timeToPlay > 0) {	// game hasn't started yet
				// add the countdown to the game window
				countdownBar = new CountdownBar;
				countdownBar.mode = 'gradientBar';
				countDownTime = (timeToPlay / 1000);
				gameCountDownGetTimer = getTimer();
				countdownBar.init(countDownTime);
				this.addEventListener(Event.ENTER_FRAME, gameCountDown);	// every frame, check 
				countdownBarContainer.addElement(countdownBar);
				if(gameContent.contains(countdownBarContainer) == false) gameContent.addElement(countdownBarContainer);

				playGameTimer = setTimeout(playGame, timeToPlay);
				
			} else {	// game already started - wait for next
				
				showGameIntermission();
				
				countdownBar = new CountdownBar;
				countdownBar.mode = 'gradientBar';
				countdownBar.init(100);
				countdownBar.addEventListener(FlexEvent.CREATION_COMPLETE, runPlaceholderCountdownBar);
				countdownBarContainer.addElement(countdownBar);

				var stopGameDelay:Number = Number(this.game.game_length_time) + timeToPlay;
				if(stopGameDelay > 0) stopGameTimer = setTimeout(stopGame, Number(this.game.game_length_time) + timeToPlay);
				else stopGame();
			}
		}
		
		// animates the countdown bar when it is ready
		private function runPlaceholderCountdownBar(e:Event):void {
			countdownBar.setSize(100);
			countdownBar.animate();
		}
		
		// remove answer media
		private function trivia_removeAnswerMedia1():void {
			triviaAnswerMedia.clipAndEnableScrolling = true;
			var smp:SimpleMotionPath;	// general use			
			var removeTriviaAnswerMedia:Animate = new Animate(triviaAnswerMedia);
			removeTriviaAnswerMedia.repeatCount = 1;
			removeTriviaAnswerMedia.duration = 500;
			smp = new SimpleMotionPath('height', triviaAnswerMedia.height, 0);
			removeTriviaAnswerMedia.motionPaths = new Vector.<MotionPath>;
			removeTriviaAnswerMedia.motionPaths.push(smp);
			removeTriviaAnswerMedia.play();
			removeTriviaAnswerMedia.addEventListener(EffectEvent.EFFECT_END, trivia_removeAnswerMedia2);
		}

		private function trivia_removeAnswerMedia2(e:EffectEvent):void {
			if(this.intermissionMsgGroup.contains(triviaAnswerMedia)) this.intermissionMsgGroup.removeElement(triviaAnswerMedia);		
		}
		
		// Change the volume of the current (and future) trivia media files. 
		private function trivia_changeVolume(e:Event):void {
			if(this.triviaSoundChannel != null) this.triviaSoundChannel.soundTransform = new SoundTransform(this.triviaVolumeSlider.value / 100);
			if(this.triviaVideoNetStream != null) this.triviaVideoNetStream.soundTransform = new SoundTransform(this.triviaVolumeSlider.value / 100);
		}
		
		public function clearGameDelayTimers():void {
			if(potentialGameDelayTimer) clearTimeout(potentialGameDelayTimer);
			if(officialGameDelayTimer) clearTimeout(officialGameDelayTimer);
		}
		
		private function startGameDelayTimers():void {
			potentialGameDelayTimer = setTimeout(showPotentialGameDelay, 30000);
			officialGameDelayTimer = setTimeout(showOfficialGameDelay, 60000);			
		}
		
		// clear existing timers if they are still running
		public function clearGameTimers():void {
			if(stopGameTimer) clearTimeout(stopGameTimer);
			if(playGameTimer) clearTimeout(playGameTimer);
			if(seedTimer) clearTimeout(seedTimer);
			if(potentialGameDelayTimer) clearTimeout(potentialGameDelayTimer);
			if(officialGameDelayTimer) clearTimeout(officialGameDelayTimer);
			if(seedGameTimer) clearInterval(seedGameTimer);
			if(triviaAnswerCountdownTimer) clearTimeout(triviaAnswerCountdownTimer);
		}

		// start the game if all data is available
		private function playGame():void {

			this.game_in_intermission = false;
			
			if(this.game.game_definition_id == 1) {
				// stop any playing media
				triviaSoundChannel.stop();
				if(triviaVideoNetStream != null) triviaVideoNetStream.play(null);
			}
			
			// clear game content area
			gameContent.removeAllElements();
			
			// remove count down timer
			stopGameTimer = setTimeout(stopGame, this.game.game_length_time);
						
			if(!this.game.implodeFiles()) {				
				gameContent.removeAllElements();
				notReadyMsg.text = "Oops! We didn\'t get the files in time. This might happen when you first join or if your internet connection is slow. The next game will start shortly..";
				gameContent.addElement(notReadyMsg);
				return;
			}
			
			gameCountDownGetTimer = getTimer();
			
			if(this.game.game_definition_id == 1) {
				trivia_showQuestion();
			}
		}
		
		private function showGameCountdown():void {
			countDownTime = (this.game.game_length_time / 1000);
			countdownBar = new CountdownBar;
			countdownBar.mode = 'gradientBar';
			countdownBar.init(countDownTime);
			this.addEventListener(Event.ENTER_FRAME, gameCountDown);	// every frame, check 
			countdownBarContainer.removeAllElements();
			countdownBarContainer.addElement(countdownBar);
			gameContent.addElement(countdownBarContainer);
		}
		
		private function gameCountDown(e:Event):void {
			
			// subtract time elapsed
			countDownTime = countDownTime - ((getTimer() - gameCountDownGetTimer) / 1000);
			gameCountDownGetTimer = getTimer();
			countdownBar.setSize(countDownTime);
			if (countDownTime < 0.01) {
				this.removeEventListener(Event.ENTER_FRAME, gameCountDown);
			}
		}
		
		private function trivia_showQuestionCountdown():void {
			triviaQuestionCountDownTime = (uint(this.game.data.question_display_time) / 1000);
			countdownBar = new CountdownBar;
			countdownBar.mode = 'gradientBar';
			countdownBar.init(triviaQuestionCountDownTime);
			this.addEventListener(Event.ENTER_FRAME, trivia_questionCountDown);	// every frame, check 
			countdownBarContainer.removeAllElements();
			countdownBarContainer.addElement(countdownBar);
			gameContent.addElement(countdownBarContainer);
		}
		
		private function trivia_questionCountDown(e:Event):void {
			
			// subtract time elapsed
			triviaQuestionCountDownTime = triviaQuestionCountDownTime - ((getTimer() - triviaQuestionCountDownGetTimer) / 1000);
			triviaQuestionCountDownGetTimer = getTimer();
			countdownBar.setSize(triviaQuestionCountDownTime);
			if (triviaQuestionCountDownTime < 0.01) {
				this.removeEventListener(Event.ENTER_FRAME, trivia_questionCountDown);
			}
		}
		
		private function trivia_showQuestion():void {
			
			// time remaining
			triviaAnswerCountdownTimer = setTimeout(trivia_showAnswer, uint(this.game.data.question_display_time));
			
			// show the question countdown timer
			triviaQuestionCountDownGetTimer = getTimer();
			trivia_showQuestionCountdown();

			this.title = 'Trivia';			
			
			gameWinnersList.removeAllElements();
			
			// question text
			if(this.game.data.word_count) this.game.data.question += " <font size='11'>" + this.game.data.word_count + ' words</font>';
			triviaQuestion.textFlow = TextConverter.importToFlow(this.game.data.question, TextConverter.TEXT_FIELD_HTML_FORMAT);
			gameContent.addElement(triviaQuestion);
			
			if(this.game.data.isMultipleChoice == '1') {
				
				// shuffle multiple choice answers
				var multipleChoicesTemp:Array = ObjectUtil.copy(this.game.data.multipleChoiceAnswers) as Array;
				var multipleChoiceAnswers:Array = [];
				while (multipleChoicesTemp.length > 0) {
					multipleChoiceAnswers.push(multipleChoicesTemp.splice(Math.round(Math.random() * (multipleChoicesTemp.length - 1)), 1)[0]);
				}
				multipleChoicesTemp = undefined;
				
				var k:String = '';
				// put the clickable answers in their place
				multipleChoiceGroup = new VGroup;
				multipleChoiceGroup.paddingTop = 15;
				var horizontalChoicesContainer:HGroup;
				i = 0;
				var answersPerRow:int = 2;
				for(k in multipleChoiceAnswers) {
					if(i % answersPerRow == 0) horizontalChoicesContainer = new HGroup;
					var choice:MultipleChoiceLabel = new MultipleChoiceLabel;
					choice.width = 200;
					choice.correct = Boolean(multipleChoiceAnswers[k]['correct']);
					choice.text = multipleChoiceAnswers[k]['answer'];
					choice.addEventListener(MouseEvent.CLICK, triviaSubmitAnswer);
					horizontalChoicesContainer.addElement(choice);
					if(i % answersPerRow == 1) multipleChoiceGroup.addElement(horizontalChoicesContainer);
					i++;
				}
				// if the last answer didn't complete a row, add the last partially full row
				if((i-1) % answersPerRow != 1) multipleChoiceGroup.addElement(horizontalChoicesContainer);
				
				var multipleChoiceGroupContainer:VGroup = new VGroup;
				multipleChoiceGroupContainer.horizontalAlign = 'center';
				multipleChoiceGroupContainer.percentWidth = 100;
				multipleChoiceGroupContainer.addElement(multipleChoiceGroup);
				gameContent.addElement(multipleChoiceGroupContainer);
				
			} else {	// fill in the blank
				// add question and answer box to the game window								
				// answer input
				triviaAnswerBox.setStyle('fontSize', 20);
				triviaAnswerBox.setStyle('focusSkin', Sprite);
				triviaAnswerBox.selectable = false;
				triviaAnswerBox.percentWidth = 100;
				triviaAnswerBox.text = '';
				triviaAnswerBox.enabled = true;
				gameContent.addElement(triviaAnswerBox);
				triviaAnswerBox.addEventListener(FlexEvent.ENTER, triviaSubmitAnswer);					
			}
			
			// use question component files if they exist
			if(int(this.game.data.num_files) > 0) {
				for(var i:int = 0; i < int(this.game.data.num_files); i++) {
					
					trace(i+':file is ready!');
					
					// get the ByteArray data from 'files' and put usable media objects in 'files_ready' object
					switch(this.game.data.files_meta[i].file_type) {
						case 'jpg':
						case 'gif':
						case 'png':
							this.game.files_ready[i] = new Loader;								
							this.game.files_ready[i].loadBytes(this.game.files[i]);
							// use file now if it is a question component
							if(this.game.data.files_meta[i].trivia_file_type_id == '1') {
								this.game.files_ready[i].contentLoaderInfo.addEventListener(Event.COMPLETE, trivia_useQuestionImageFile);
							}
							break;
						case 'mp3':

							this.game.files_ready[i] = new MP3FileReferenceLoader();
							var tftid:String = this.game.data.files_meta[i].trivia_file_type_id;							
							if(tftid == '1' || tftid == '2') {
								this.game.files_ready[i].addEventListener(MP3SoundEvent.COMPLETE, mp3LoaderCompletePlayNow);

								// use file now if it is a question component
								if(tftid == '1') trivia_useQuestionComponentFile(i);								
							} else if(tftid == '3') {								
								this.game.files_ready[i].addEventListener(MP3SoundEvent.COMPLETE, mp3LoaderCompletePlayLater);
								this.game.files_ready[i].loadBytes(this.game.files[i]);
							}
							
							break;
						case 'flv':	// videos are set up on the fly at play time using TriviaVideo
							// use file now if it is a question component
							if(this.game.data.files_meta[i].trivia_file_type_id == '1') trivia_useQuestionComponentFile(i);
							break;
					}
				}
			}				
			
			gameContainer.addElement(gameContent);
			this.addElement(gameContainer);
			
			if(this.room.getFocus() == null || this.room.getFocus() == this) triviaAnswerBox.setFocus();
		}
		
		private function trivia_showAnswer():void {
						
			triviaAnswerBox.removeEventListener(FlexEvent.ENTER, triviaSubmitAnswer);
			triviaSoundChannel.stop();
			if(triviaVideoNetStream != null) triviaVideoNetStream.close();
			
			// cancel object replication
			// the game is over, so the game objects are no longer needed anywhere
			this.room.netGroup.removeWantObjects(this.game.start_object_id, this.game.end_object_id);
			this.room.netGroup.removeHaveObjects(this.game.start_object_id, this.game.end_object_id);
			
			// garbage collection - delete shared objects related to this game
			for(var i:int = this.game.start_object_id; i <= this.game.end_object_id; i++) {
				delete this.room.objects[i];
			}
			
			this.gameContent.removeAllElements();
			this.countdownBarContainer.removeAllElements();
			
			triviaAnswerScreen = new VGroup;
			triviaAnswerScreen.percentWidth = 100;
			triviaAnswerScreen.gap = 10;
			triviaAnswerScreen.paddingBottom = triviaAnswerScreen.paddingTop = 10;
			var triviaAnswerMsg:RichEditableText = new RichEditableText;
			triviaAnswerMsg.editable = false;
			triviaAnswerMsg.selectable = false;
			triviaAnswerMsg.percentWidth = 100;
			triviaAnswerMsg.setStyle('textAlign', 'center');
			triviaAnswerScreen.addElement(triviaAnswerMsg);
			this.gameContent.addElement(triviaAnswerScreen);
			
			// if in game testing mode, create buttons for deleting or approving the viewed game
			if(this.game.id && this.room.getName() == this.trivia_testing_room_name) {
				this.trivia_id_to_process = this.game.data.id;
				
				trivia_testing_buttons = new HGroup;
				
				var approve:Button = new Button;
				approve.label = 'Approve';
				approve.addEventListener(MouseEvent.CLICK, processUnapprovedTrivia);
				
				var deny:Button = new Button;
				deny.label = 'Deny';
				deny.addEventListener(MouseEvent.CLICK, processUnapprovedTrivia);
				
				trivia_testing_buttons.addElement(approve);
				trivia_testing_buttons.addElement(deny);
				
				var trivia_testing_buttons_container:VGroup = new VGroup;
				trivia_testing_buttons_container.horizontalAlign = 'center';
				trivia_testing_buttons_container.percentWidth = 100;
				trivia_testing_buttons_container.addElement(trivia_testing_buttons);
				
				triviaAnswerScreen.addElement(trivia_testing_buttons_container);
			}
			
			var answer:String = new String;
			// display response
			if(this.game.ready) {
				
				// determine the answer
				if(this.game.data.isMultipleChoice == '1') {
					answer = "<font size='22'><b>" + String(this.game.data.multipleChoiceAnswers[0].answer).substr(0, 1).toUpperCase() + String(this.game.data.multipleChoiceAnswers[0].answer).substr(1) + "</b> is the answer.</font>";
				} else {
					answer = "<font size='22'><b>" + String(this.game.data.correctAnswers[0]).substr(0, 1).toUpperCase() + String(this.game.data.correctAnswers[0]).substr(1) + "</b> is the answer.</font>";					
				}
				
				triviaAnswerMsg.textFlow = TextConverter.importToFlow(answer, TextConverter.TEXT_FIELD_HTML_FORMAT);
				if(this.game.data.extra_info.length > 0) {
					var extraInfo:RichEditableText = new RichEditableText;
					extraInfo.selectable = extraInfo.editable = false;
					extraInfo.percentWidth = 100;
					extraInfo.setStyle('textAlign', 'center');
					var extraInfoText:String =  this.game.data.extra_info;
					extraInfo.textFlow = TextConverter.importToFlow('<font family="Lucida Sans">' + extraInfoText + '</font>', TextConverter.TEXT_FIELD_HTML_FORMAT);
					triviaAnswerScreen.addElement(extraInfo);
				}
				
				// show post game trivia answer media
				if(int(this.game.data.num_files) > 0) {
					for(i = 0; i < int(this.game.data.num_files); i++) {
						if(this.game.data.files_meta[i].trivia_file_type_id == '2') trivia_useAnswerComponentFile(i);
					}
				}
				
			} else {
				triviaAnswerMsg.textFlow = TextFlowUtil.importFromString("Hold your horses for the next game.");				
			}
		}		
		
		// used with FlexEvent.ADD because the display list doesn't have the image width until contentLoader is done
		private function trivia_useQuestionImageFile(e:Event):void {
			triviaQuestionImageContainer = new UIComponent;
			triviaQuestionImage = e.target.content;
			triviaQuestionImageContainer.addChild(triviaQuestionImage);
			gameContent.addElement(triviaQuestionImageContainer);			
			triviaQuestionImageContainer.height = triviaQuestionImage.height;
			this.resizeGameWindow(new Event(Event.RESIZE));
		}
		
		// this function knows what to do with 'files_ready' question component media
		private function trivia_useQuestionComponentFile(i:int):void {
			// get the ByteArray data from 'files' and put usable media objects in 'files_ready' object
			switch(this.game.data.files_meta[i].file_type) {
				case 'jpg':
				case 'gif':
				case 'png':
					break;
				case 'mp3':
					this.game.files_ready[i].loadBytes(this.game.files[i]);
					var triviaPlayerButton:Button = new Button;
					triviaPlayerButton.label = 'Play';
					triviaPlayerButton.addEventListener(MouseEvent.CLICK, playTriviaSound);
					var tmp:HGroup = new HGroup;
					tmp.percentWidth = 100;
					tmp.horizontalAlign = 'center';
					tmp.verticalAlign = 'middle';
					tmp.addElement(triviaPlayerButton);
					tmp.addElement(this.triviaVolumeSlider);
					gameContent.addElement(tmp);
					break;
				case 'flv':									
					setupTriviaVideo();
					triviaVideo.file = this.game.files[i];
					if(this.window_open) playTriviaVideo(new MouseEvent(MouseEvent.CLICK));
					triviaVideoContainer = new UIComponent();
					triviaVideoContainer.width = triviaVideo.width;
					triviaVideoContainer.addChild(triviaVideo);
					var video_controls:HGroup = new HGroup;
					video_controls.percentWidth = 100;
					video_controls.verticalAlign = 'middle';
					video_controls.horizontalAlign = 'center';
					var triviaVideoPlayerButton:Button = new Button;
					triviaVideoPlayerButton.label = 'Play';
					triviaVideoPlayerButton.addEventListener(MouseEvent.CLICK, playTriviaVideo);
					video_controls.addElement(triviaVideoPlayerButton);
					video_controls.addElement(this.triviaVolumeSlider);
					var videoArea:VGroup = new VGroup;
					videoArea.percentWidth = 100;
					videoArea.horizontalAlign = 'center';
					videoArea.addElement(video_controls);
					videoArea.addElement(triviaVideoContainer);
					gameContent.addElement(videoArea);
			}
		}
		
		// this function knows what to do with 'files_ready' answer component media
		private function trivia_useAnswerComponentFile(i:int):void {
			triviaAnswerMedia = new Group;
			triviaAnswerMedia.percentWidth = 100;

			// get the ByteArray data from 'files' and put usable media objects in 'files_ready' object
			switch(this.game.data.files_meta[i].file_type) {
				case 'jpg':
				case 'gif':
				case 'png':
					var tmp:UIComponent = new UIComponent;
					triviaQuestionImage = this.game.files_ready[i].content;
					tmp.addChild(triviaQuestionImage);
					tmp.height = triviaAnswerMedia.height = triviaQuestionImage.height;	
					tmp.width = triviaQuestionImage.width;	
					triviaAnswerMedia.addElement(tmp);
					triviaAnswerScreen.addElement(triviaAnswerMedia);			
					this.resizeGameWindow(new Event(Event.RESIZE));
					break;
				case 'mp3':
					this.game.files_ready[i].loadBytes(this.game.files[i]);
					var triviaPlayerButton:Button = new Button;
					triviaPlayerButton.label = 'Play';
					triviaPlayerButton.addEventListener(MouseEvent.CLICK, playTriviaSound);
					triviaAnswerMedia.addElement(triviaPlayerButton);
					var buttonArea:HGroup = new HGroup;
					buttonArea.percentWidth = 100;
					buttonArea.horizontalAlign = 'center';
					buttonArea.verticalAlign = 'middle';
					buttonArea.addElement(triviaPlayerButton);
					buttonArea.addElement(this.triviaVolumeSlider);
					triviaAnswerScreen.addElement(buttonArea);
					break;
				case 'flv':									
					setupTriviaVideo();
					triviaVideo.file = this.game.files[i];
					if(this.window_open) playTriviaVideo(new MouseEvent(MouseEvent.CLICK));
					triviaVideoContainer = new UIComponent();
					triviaVideoContainer.width = triviaVideo.width;
					triviaVideoContainer.addChild(triviaVideo);
					triviaVideoContainer.height = triviaVideo.height;
					var video_controls:HGroup = new HGroup;
					video_controls.percentWidth = 100;
					video_controls.verticalAlign = 'middle';
					video_controls.horizontalAlign = 'center';
					var triviaVideoPlayerButton:Button = new Button;
					triviaVideoPlayerButton.label = 'Play';
					triviaVideoPlayerButton.addEventListener(MouseEvent.CLICK, playTriviaVideo);
					video_controls.addElement(triviaVideoPlayerButton);
					video_controls.addElement(this.triviaVolumeSlider);
					var videoArea:VGroup = new VGroup;
					videoArea.percentWidth = 100;
					videoArea.horizontalAlign = 'center';
					videoArea.addElement(video_controls);
					videoArea.addElement(triviaVideoContainer);
					triviaAnswerMedia.addElement(videoArea);
					triviaAnswerScreen.addElement(triviaAnswerMedia);
			}			
		}
		
		// When a player gets the right ansewr, this sound plays. 
		private function trivia_playCorrectAnswerSound(i:uint):void {
			this.game.files_ready[i].loadBytes(this.game.files[i]);
		}

		private function playTriviaVideo(e:MouseEvent = null):void {
			triviaVideoNetStream.play(null);
			triviaVideoNetStream.appendBytesAction(NetStreamAppendBytesAction.RESET_BEGIN);
			triviaVideoNetStream.appendBytes(triviaVideo.file);
			triviaVideo.attachNetStream(triviaVideoNetStream);
		}
		
		// a game file is complete. stitch together the chunks and put it in the game files.
		private function implodeGameFiles(g:Object):void {
			for(var i:uint = uint(g.start_object_id)+1; i <= uint(g.end_object_id); i++) {
				this.game.files[this.room.objects[i].file_num].writeBytes(this.room.objects[i].data);
			}
		}
		
		// Start playing the sound as soon as it is loaded.
		private function mp3LoaderCompletePlayNow(e:MP3SoundEvent):void {
			if(triviaSound != null) triviaSound = e.sound;
			if(this.window_open) { 
				triviaSoundChannel = e.sound.play();
				triviaSoundChannel.soundTransform = new SoundTransform(this.triviaVolumeSlider.value / 100);
			}
		}
		
		// Store the sound rather than play it immediately.
		private function mp3LoaderCompletePlayLater(e:MP3SoundEvent):void {
			this.game.trivia_correct_answer_sound = e.sound;
		}


		// play the trivia sound again. stop first
		private function playTriviaSound(e:MouseEvent):void {
			triviaSoundChannel.stop();
			if(this.window_open) { 
				triviaSoundChannel = triviaSound.play();
				triviaSoundChannel.soundTransform = new SoundTransform(this.triviaVolumeSlider.value / 100);
			}
		}
		
		// stop playing the trivia sound
		private function stopTriviaSound():void {
			triviaSoundChannel.stop();
		}
		
		// set up trivia video
		private function setupTriviaVideo():void {
			var nc:NetConnection = new NetConnection();
			nc.connect(null);
			triviaVideoNetStream = new NetStream(nc);
			triviaVideoNetStream.soundTransform = new SoundTransform(this.triviaVolumeSlider.value / 100);
			triviaVideoNetStream.client = this;
			triviaVideo = new TriviaVideo();			
		}
		
		// video info callbacks - in the future these need to be encapsulated in TriviaVideoCallbacks
		public function onMetaData(info:Object):void{
			triviaVideoContainer.width = triviaVideo.width = info.width;
			triviaVideoContainer.height = triviaVideo.height = info.height;
		}
		
		public function onXMPData(info:Object):void{}		
		
		private function triviaSubmitAnswer(e:Event):void {
			
			var correct:Boolean = false;		// is the response correct?
			
			if(this.game.data.isMultipleChoice == '1') {

				correct = e.currentTarget.correct;
				for(var i:int = 0; i < multipleChoiceGroup.numElements; i++) {
					var row:HGroup = multipleChoiceGroup.getElementAt(i) as HGroup;
					for(var j:int = 0; j < row.numElements; j++) {
						var choice:MultipleChoiceLabel = row.getElementAt(j) as MultipleChoiceLabel;
						choice.deactivate();
						choice.removeEventListener(MouseEvent.CLICK, triviaSubmitAnswer);
					}
				}

			} else {	// fill in the blank
				triviaAnswerBox.enabled = false;	// don't allow more typing
				triviaAnswerBox.removeEventListener(FlexEvent.ENTER, triviaSubmitAnswer);
				triviaAnswerBox.focusEnabled = false;
				triviaAnswerBox.focusRect = false;
				this.setFocus();
				
				// account for all possible correct answers
				var userAnswer:String = triviaAnswerBox.text.toLowerCase();
				for(var k:String in this.game.data.correctAnswers) {
					var correctAnswer:String = this.game.data.correctAnswers[k].toLowerCase();
					if(StringUtil.trim(this.game.data.correctAnswers[k].toLowerCase()) == StringUtil.trim(userAnswer)) {
						correct = true;
						break;
					} else {	// questionable hard-coded user friendliness for single digit answers
						if(		(userAnswer == 'one' && correctAnswer == '1') || (userAnswer == '1' && correctAnswer == 'one') ||
							(userAnswer == 'two' && correctAnswer == '2') || (userAnswer == '2' && correctAnswer == 'two') ||
							(userAnswer == 'three' && correctAnswer == '3') || (userAnswer == '3' && correctAnswer == 'three') ||
							(userAnswer == 'four' && correctAnswer == '4') || (userAnswer == '4' && correctAnswer == 'four') ||
							(userAnswer == 'five' && correctAnswer == '5') || (userAnswer == '5' && correctAnswer == 'five') ||
							(userAnswer == 'six' && correctAnswer == '6') || (userAnswer == '6' && correctAnswer == 'six') ||
							(userAnswer == 'seven' && correctAnswer == '7') || (userAnswer == '7' && correctAnswer == 'seven') ||
							(userAnswer == 'eight' && correctAnswer == '8') || (userAnswer == '8' && correctAnswer == 'eight') ||
							(userAnswer == 'nine' && correctAnswer == '9') || (userAnswer == '9' && correctAnswer == 'nine') ||
							(userAnswer == 'ten' && correctAnswer == '10') || (userAnswer == '10' && correctAnswer == 'ten') ) {
							correct = true;
							break;
						}
					}
				}				
			}
			
			// play an animation in response to the answer
			var triviaGameAnswerResponseContainer:VGroup = new VGroup;
			triviaGameAnswerResponseContainer.verticalAlign = 'middle';
			triviaGameAnswerResponseContainer.horizontalAlign = 'center';
			triviaGameAnswerResponseContainer.width = gameContainer.width;
			triviaGameAnswerResponseContainer.height = gameContainer.height;
			
			var answerResponseEmoticon:Label = new Label;
			answerResponseEmoticon.setStyle('color', 0xFFFFFF);
			answerResponseEmoticon.setStyle('fontSize', '150');
			answerResponseEmoticon.setStyle('fontWeight', 'bold');
			answerResponseEmoticon.setStyle('fontFamily','Tahoma');
			//answerResponseEmoticon.text = this.game.data.correctAnswers[0] + ' is right!';
			
			var gradientColors:Array = new Array;
			var emoticon:Object;
			
			if(correct) {
								
				gradientColors = [Math.random()*0x1FFFFF, Math.random()*0x2FFFFF];
				
				//				answerResponseEmoticon.text = '+' + this.game.points;
				emoticon = emoticons.getRandomHappy();
				answerResponseEmoticon.text = emoticon.text;
				triviaGameAnswerResponseContainer.addElement(answerResponseEmoticon);
/*				
				var answerResponseMsg:Label = new Label;
				answerResponseMsg.text = this.game.points + ' points';
				answerResponseMsg.setStyle('fontSize', 25);
				answerResponseMsg.setStyle('color', 0xFFFFFF);
				triviaGameAnswerResponseContainer.addElement(answerResponseMsg);
*/
				var variables:URLVariables = new URLVariables;
				variables.answer = triviaAnswerBox.text;
				variables.user_id = this.room.user.userID;
				variables.game_id = this.game.id;
				variables.round_id = this.game.round_id;
				
				var request:URLRequest = new URLRequest(this.room.CONFIG.SITE_URL + "/game_response.php");
				request.method = URLRequestMethod.POST;
				request.data = variables;
				loader = new URLLoader;
				loader.addEventListener(Event.COMPLETE, handleTriviaSubmitAnswer);
				//loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
				
				if(this.game.trivia_correct_answer_sound == null) triviaSounds.correct();
				else this.game.trivia_correct_answer_sound.play();
				
				try {
					loader.load(request);
				} catch (error:SecurityError) {
					trace("A SecurityError has occurred.");
				}
			} else {
				
				gradientColors = [0x7E2217, 0xC25A7C];
				emoticon = emoticons.getRandomSad();
				answerResponseEmoticon.text = emoticon.text;
				if(emoticon.sideways) answerResponseEmoticon.rotation = 90;
				triviaGameAnswerResponseContainer.addElement(answerResponseEmoticon);
			}
			
			if(answerResponseEmoticon.text.length > 3) answerResponseEmoticon.setStyle('fontSize', 100);
			
			// create a rectangle the size of the game window
			triviaGameAnswerResponse = new VGroup;

			triviaGameAnswerResponse.graphics.beginGradientFill(
				GradientType.RADIAL, 	// type
				gradientColors, 		// colors
				[1,1], 					// alphas
				[50,255],				// ratios
				new Matrix
			);
			triviaGameAnswerResponse.graphics.drawRect(0, 0, gameContainer.width, gameContainer.height);
			triviaGameAnswerResponse.graphics.endFill();
			triviaGameAnswerResponse.width = gameContainer.width;
			triviaGameAnswerResponse.height = gameContainer.height;
			triviaGameAnswerResponse.verticalAlign = 'middle';
			triviaGameAnswerResponse.horizontalAlign = 'center';
			triviaGameAnswerResponse.depth = 11;
			triviaGameAnswerResponse.alpha = 0;

			triviaGameAnswerResponse.addElement(triviaGameAnswerResponseContainer);
			
			// animations
			var smp:SimpleMotionPath;	// general use
			
			triviaGameResponsePulse = new Animate(answerResponseEmoticon);
			triviaGameResponsePulse.target = answerResponseEmoticon;
			triviaGameResponsePulse.repeatCount = 15;
			triviaGameResponsePulse.duration = 300 * Math.random() + 50;
			triviaGameResponsePulse.repeatBehavior = 'reverse';
			smp = new SimpleMotionPath('alpha', 0.50, 1);
			triviaGameResponsePulse.motionPaths = new Vector.<MotionPath>;
			triviaGameResponsePulse.motionPaths.push(smp);
			triviaGameResponsePulse.play();
			
			if(emoticon.sideways && correct) {
				var msgAnimator2:Animate = new Animate(answerResponseEmoticon);
				msgAnimator2.repeatCount = 1;
				msgAnimator2.duration = 400;
				msgAnimator2.repeatBehavior = 'reverse';
				msgAnimator2.motionPaths = new Vector.<MotionPath>;
				smp = new SimpleMotionPath('rotation', 0, 450);
				msgAnimator2.motionPaths.push(smp);				
				msgAnimator2.play();
				
			}
			
			gameContainer.addElement(triviaGameAnswerResponse);
			
			var a:Animate = new Animate(triviaGameAnswerResponse);
			a.repeatCount = 1;
			a.duration = 250;
			a.repeatBehavior = 'reverse';
			a.motionPaths = new Vector.<MotionPath>;
			smp = new SimpleMotionPath('alpha', 0, 1);
			a.motionPaths.push(smp);
			a.play();
			a.addEventListener(EffectEvent.EFFECT_END, fadeOutTriviaGameResponse);
		}
		
		private function fadeOutTriviaGameResponse(e:EffectEvent):void {
			var a:Animate = new Animate(triviaGameAnswerResponse);
			a.repeatCount = 1;
			a.duration = 250;
			a.startDelay = 1000;
			a.repeatBehavior = 'reverse';
			var smp:SimpleMotionPath = new SimpleMotionPath('alpha', 1, 0);
			a.motionPaths = new Vector.<MotionPath>;
			a.motionPaths.push(smp);
			a.play();
			a.addEventListener(EffectEvent.EFFECT_END, removeTriviaGameResponse);
		}
		
		private function removeTriviaGameResponse(e:EffectEvent):void {
			triviaGameResponsePulse.stop();
			gameContainer.removeElement(triviaGameAnswerResponse);
		}
		
		private function handleTriviaSubmitAnswer(e:Event):void {
			try {
				var response:Object = new Object;
				response = JSON.decode(loader.data);
				if(response.success == '1') {
					
					// tell the world that you won
					var message:Object = new Object;
					message.type = 'game winner';
					message.sender = this.room.netConnection.nearID;
					message.game_id = this.game.id;
					message.points_won = this.game.points;
					this.room.netGroup.post(message);
					this.room.receiveMessage(message);
					
				} else {
					// do unsuccessful stuff
					Alert.show(response.msg, 'Oops!');
				}
			} catch (e:Error) {
				trace("Could not finish game.");
			}	
		}
		
		// stop the current game
		private function stopGame():void {

			// clear the game window and start intermission
			gameContent.removeAllElements();			
			
			showGameIntermission();
						
			this.room.seedGame();	// seed game
		}
				
		private function processUnapprovedTrivia(e:MouseEvent):void {
			trivia_testing_buttons.removeAllElements();
			
			var variables:URLVariables = new URLVariables;
			variables.action = e.currentTarget.label;
			variables.trivia_id = this.trivia_id_to_process;
			this.trivia_id_to_process = new uint;	// unset
			var request:URLRequest = new URLRequest(this.room.CONFIG.SITE_URL + "/process_unapproved_trivia.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;
			loader = new URLLoader;
			//			loader.addEventListener(Event.COMPLETE, adminifySaveHandler);
			//loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			try {
				loader.load(request);
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}	
		}
		
		// show potential delay message in intermission
		private function showPotentialGameDelay():void {
			intermissionMsg.alpha = 0;
			intermissionMsg.text = "Getting the next game is taking longer than usual.";
			setTimeout(showIntermissionMsg, 100);
		}
		
		// hack for RichEditableText flicker when replacing text that is setStyle('textAlign', 'center') 
		// the problem is that it will be left-aligned for a split second, causing a jump
		private function showIntermissionMsg():void {
			intermissionMsg.alpha = 1;
		}
		
		// show potential delay message in intermission
		private function showOfficialGameDelay():void {
			intermissionMsg.alpha = 0;
			intermissionMsg.text = "Game is delayed. We'll be back a soon as possible.";
			setTimeout(showIntermissionMsg, 100);
		}

		// get the next game
		public function getGame():void {
			var variables:URLVariables = new URLVariables;
			variables.wall_id = this.room.id;
			variables.get = 1;
			if(this.room.getName() == this.trivia_testing_room_name) variables.trivia_testing_mode = true;
			var request:URLRequest = new URLRequest(this.room.CONFIG.SITE_URL + "/get_game.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;
			loaders['getGame'] = new URLLoader;
			loaders['getGame'].addEventListener(Event.COMPLETE, handleGetGame);
			//loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			try {
				loaders['getGame'].load(request);
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}
		}
		
		// process the get game request
		private function handleGetGame(e:Event):void {
			try {
				var response:Object = new Object;
				response = JSON.decode(loaders['getGame'].data);
				
				if(response.success == '1') {
					
					// process objects. since this is an Object they are not in order. they must be received in order, 
					// so the loop happens twice
					var objectArray:Array = new Array();
					var k:String = new String;
					for(k in response.objects) {
						response.objects[k].object_id = k;	// used to sort the array being created
						objectArray.push(response.objects[k]);
					}
					objectArray.sortOn('object_id');
					for(k in objectArray) {
						this.room.processNewObject(Number(objectArray[k].object_id), objectArray[k]);	// do something with the new object						
					}
					
				} else {
					// do unsuccessful stuff
					Alert.show(response.msg, 'Oops!');
				}
				
				delete loaders['getGame'];	// reclaim memory
				
			} catch (e:Error) {
				trace("Could not get the game. " + e.message + ' ' + e.getStackTrace());
			}	
		}
		
		// round data is disseminated through the P2P group so its arrival time should be considered unpredictable
		public function handleRoundData(round_data:Object):void {
			this.roundData.removeAllElements();
			
			// add the round data to the intermission screen
			if(this.game_in_intermission == true) {
				
				var i:int = 0;
				var m:String = '';				// remember the last index in order to compare the point values to account for ties
				var is_me:Boolean = false;		// mark whether current user
				var entry:HGroup = new HGroup;
				var place:Label = new Label;
				var username:Label = new Label;
				var points:Label = new Label;
				
				i = 1;
				var k:String = '';
				var caption:RichText = new RichText;
				caption.textFlow = TextFlowUtil.importFromString("<span fontSize='18'>Game  " + round_data.last_round_num + " of 10 - " + " Round #" +  round_data.id  + "</span>");
				var captionContainer:VGroup = new VGroup;
				captionContainer.percentWidth = 100;
				captionContainer.horizontalAlign = 'center';
				captionContainer.addElement(caption);
				captionContainer.paddingBottom = 6;
				this.roundData.addElement(captionContainer);
				if(round_data.table.length == 0) {
					var noneMsg:Label = new Label;
					noneMsg.setStyle('fontSize', 15);
					noneMsg.text = "No points have been scored in this round.";
					this.roundData.addElement(noneMsg);
				}

				m = '';	// remember the last index in order to compare the point values to account for ties
				is_me = false;
				for(k in round_data.table) {
					if(this.room.user.username == round_data.table[k].username) is_me = true;
					entry = new HGroup;
					place = new Label;
					username = new Label;
					points = new Label;
					place.setStyle('fontSize','15');
					username.setStyle('fontSize','15');
					points.setStyle('fontSize','15');
					if(round_data.table[m] == undefined) place.text = '1.';
					else if((round_data.table[m].points != round_data.table[k].points)) place.text = i.toString() + '.';
					place.width = 40;
					entry.addElement(place);
					username.width = 200;
					username.maxDisplayedLines = 1;
					username.text = round_data.table[k].username;
					entry.addElement(username);
					points.text = round_data.table[k].points;
					entry.addElement(points);
					this.roundData.addElement(entry);
					i++;
					m = k;
					is_me = false;
				}

				var roundContainer:VGroup = new VGroup;
				roundContainer.percentWidth = 100;
				roundContainer.horizontalAlign = 'center';
				roundContainer.addElement(this.roundData);
				this.gameContent.addElement(roundContainer);
			}
		}
		
		// fade out the round result screen
		private function fadeOutRoundResultScreen():void {
			var a:Animate = new Animate(roundResultScreen);
			a.repeatCount = 1;
			a.duration = 250;
			a.startDelay = 1000;
			a.repeatBehavior = 'reverse';
			var smp:SimpleMotionPath = new SimpleMotionPath('alpha', 1, 0);
			a.motionPaths = new Vector.<MotionPath>;
			a.motionPaths.push(smp);
			a.play();
			a.addEventListener(EffectEvent.EFFECT_END, removeRoundResultScreen);
		}
		
		// remove the round result screen
		private function removeRoundResultScreen(e:EffectEvent):void {
			if(gameContainer.contains(roundResultScreen)) gameContainer.removeElement(roundResultScreen);
		}		
		
		public function clearGameForExit():void {
			this.countdownBarContainer.removeAllElements();
			this.clearGameTimers();
			this.gameContent.removeAllElements();
			this.removeAllElements();
			PopUpManager.removePopUp(this);
			this.game = new Game(this.room);
			this.gameWinnersList.removeAllElements();
			this.triviaSoundChannel.stop();
			this.removeEventListener(Event.ENTER_FRAME, gameCountDown);
			this.removeEventListener(Event.ENTER_FRAME, trivia_questionCountDown);
			if(this.triviaVideoNetStream != null) this.triviaVideoNetStream.close();
		}
	}
}