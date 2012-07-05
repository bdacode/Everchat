package
{
	import com.adobe.crypto.HMAC;
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;
	import com.adobe.serialization.json.JSONParseError;
	import com.facebook.graph.Facebook;
	
	import creacog.spark.components.ResizeableTitleWindow;
	import creacog.spark.events.TitleWindowBoundsEvent;
	import creacog.spark.skins.ResizeableTitleWindowMacSkin;
	import creacog.spark.skins.ResizeableTitleWindowSkin;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.errors.IOError;
	import flash.events.*;
	import flash.events.MouseEvent;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.media.Camera;
	import flash.media.Microphone;
	import flash.media.Sound;
	import flash.media.SoundChannel;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.*;
	import flash.net.NetConnection;
	import flash.system.System;
	import flash.text.TextField;
	import flash.text.TextFormat;
	import flash.ui.Mouse;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import flashx.textLayout.conversion.TextConverter;
	import flashx.textLayout.formats.LineBreak;
	
	import flexlib.containers.FlowBox;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Canvas;
	import mx.containers.Panel;
	import mx.controls.Alert;
	import mx.controls.Menu;
	import mx.controls.Text;
	import mx.core.DragSource;
	import mx.core.SoundAsset;
	import mx.core.UIComponent;
	import mx.events.*;
	import mx.events.CloseEvent;
	import mx.events.DragEvent;
	import mx.events.FlexEvent;
	import mx.events.MenuEvent;
	import mx.graphics.GradientEntry;
	import mx.graphics.RadialGradient;
	import mx.graphics.SolidColor;
	import mx.graphics.Stroke;
	import mx.managers.DragManager;
	import mx.managers.PopUpManager;
	import mx.managers.SystemManager;
	import mx.utils.ArrayUtil;
	
	import org.audiofx.mp3.MP3FileReferenceLoader;
	import org.audiofx.mp3.MP3SoundEvent;
	import org.osmf.audio.AudioElement;
	
	import spark.components.BorderContainer;
	import spark.components.Button;
	import spark.components.CheckBox;
	import spark.components.DropDownList;
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.Label;
	import spark.components.RichEditableText;
	import spark.components.RichText;
	import spark.components.Scroller;
	import spark.components.TextArea;
	import spark.components.TextInput;
	import spark.components.TitleWindow;
	import spark.components.VGroup;
	import spark.core.SpriteVisualElement;
	import spark.effects.Animate;
	import spark.effects.Rotate;
	import spark.effects.Rotate3D;
	import spark.effects.animation.MotionPath;
	import spark.effects.animation.SimpleMotionPath;
	import spark.events.TitleWindowBoundsEvent;
	import spark.primitives.Graphic;
	import spark.primitives.Rect;
	import spark.utils.TextFlowUtil;
	
	public class Wall extends Group {	
		public var mainLayer:Group = new Group;
		private var titleAndCamGrid:VGroup = new VGroup;
		public var netConnection:NetConnection;
		public var netGroup:NetGroup;
		private var groupspec:GroupSpecifier;
		private const VIDEO_CELL_W:int = 160;			
		private const VIDEO_CELL_H:int = 120;
		private const USER_LIST_X:int = 655;
//		private var camWindows:Array = new Array(MAX_CAMERAS);
		private var camGrid:CamGrid = new CamGrid;
		private var loader:URLLoader;
		private var loaders:Object = new Object;		// store loaders with name keys
		public var objects:Object = new Object;			// stores P2P objects indexed by object_id. object_id's are only unique to a wall
		private var sharedObjects:Array = new Array;	// array of P2PSharedObjects which download, split, and share chunks of files
		private var requires_login:Boolean;
		public var peers:Object;						// primary store of information about who is in the room
		public var peersArray:Array =  new Array;		// used as a convenient way to sort into a displayed user list
		private var chat:Chat;
		public var user:User;
		private var myCamIndex:int = -1;				// store local camera index
		private var wallNameLabel:Label = new Label;
		private var addCameraButton:Button = new Button;
		private var pushToTalkButton:Button = new Button;
		private var inviteButton:Button = new Button;
		private var exitButton:Button = new Button;	
		private var usernameInput:TextInput = new TextInput;
		private var submitUsernameButton:Button = new Button();
		private var settingsButton:Button = new Button();
		private var faveButton:Button = new Button();
		private var playButton:Button = new Button();
		private var formValidateAdmin:Group = new Group();
		public var master:everchat;
		public var popupCanvas:PopupCanvas;			// for messages and forms that take up entire screen
//		private const SERVER:String = "rtmfp://stratus.adobe.com/";
//		private const DEVKEY:String = "ebd8c977378a81d1513eed61-06340b121729";
		private const SERVER:String = "rtmfp://184.82.95.194/multicast"; 
		private const DEVKEY:String = "";
		private const STREAM_NAME_DELIM:String = '##';
		[Bindable]
		private var connected:Boolean = false;
		public var titleBar:VGroup = new VGroup;
		private var topMenu:HGroup = new HGroup;
		private var adminScreen:WallAdminScreen;
		private var passPromptInput:TextInput = new TextInput;
		private var passPromptSubmit:Button = new Button;
		// invite friends popup
		private var inviteFriendsCloseButton:Button = new Button();
		private var mic:Microphone;
		private var want_objects_requested:Boolean = false;		// has NetGroup.addWantObjects() been called?
		public var ban_window:BanWindow;		// bans a user from a room
		public var flag_window:FlagWindow;		// flags a user (anyone can do this)
		private var last_object_id:Number = 0;	// last object id from wall record in DB	
		private var last_started_game_object_id:Number = 0;	// last started game object id so joining users can addWantObjects using the right lower boundary
		private var banner:Object;
		public var bannerContainer:UIComponent;
		public const BANNER_HEIGHT:uint = 60;
		public const BANNER_WIDTH:uint = 640;
		public const MAX_BANNER_SIZE:uint = 100000;	// max file size in bytes
		private var reportEstimatedMembersInterval:uint;	// timer that makes a seeder report netGroup.estimatedMemberCount to the server
		private var room_address_group:HGroup = new HGroup;
		private var room_address_label:Label = new Label;
		private var room_address_copy:Label = new Label;
		
		// games
		public var game_on:int = 0;			// 1=wall is playing games 0=wall is not playing games
		private var gameWindow:GameWindow;

		// members
		public var CONFIG:Object;
		private var password:String = new String;		// password protected wall
		private var state:int = 0;						// holds state ID. 1 = adminScreen
		public var require_account:int;					// allow anonymous users?
		private var gotAttributes:Boolean = false;		// true if the last refreshAttributes was successful
		public var url_name:String = new String;		// wall name url with url safe characters only 
		private var creator_user_id:int;				// userID of the account that created the wall
		public var banner_file_id:int = 0;				// file_id of the banner to display
		public var banner_file_name:String = '';		// file_name of the banner to display
		public var banner_last_object_id:int = 0;		// object_id of the most recent banner change
		private var banner_shared_object_index:Number;	// used in seeding and propogating banner data
		public var include_in_search:int;				// 1=wall is playing games 0=wall is not playing games
		public var city_id:uint;				// 1=wall is playing games 0=wall is not playing games
		
		// ui
		private var userList:VGroup = new VGroup;
		private var userListHeader:Label = new Label;
		private var userListScroller:Scroller = new Scroller;
		private var userListActionMenu:Menu = new Menu;
		private var userListScrollerContainer:Group = new Group;
		[Embed(source="everchat_s.png")]
		private var logo:Class;
		private var logoBitmap:Bitmap;
		private var logoContainer:UIComponent = new UIComponent;
		private const TOP_MENU_SPACING:uint = 35;
		
		
		private const OOPS:String = 'Oops!';			// used as the title for Alert error messages
		
		// forms
		private var inviteFacebookCheckbox:CheckBox = new CheckBox;		// checkbox on the Invite screen that requests to post to user's FB status

		// timers
		private var checkForTalkTimer:uint;			// checks for a talking user
				
		public function Wall(master:everchat) {
			super();
			this.master = master;
			this.CONFIG = this.master.CONFIG;	// set the universal config
			this.user = this.master.user;
			this.popupCanvas = new PopupCanvas(this);
			this.gameWindow = new GameWindow(this); 

			// Set up in terms of the master/parent/calling object.
			this.width = this.minWidth = 1070;
			this.mainLayer.percentWidth = 100;
			this.height = this.mainLayer.height = this.master.height;
			
			// top menu and cam windows
			this.titleAndCamGrid.addElement(titleBar);
			this.titleAndCamGrid.addElement(camGrid);
			this.mainLayer.addElement(titleAndCamGrid);
			
			this.addElement(mainLayer);
			
			this.userListHeader.setStyle('fontWeight','bold');
			this.userList.addElement(userListHeader);
			this.userListHeader.width = userList.width = this.userListScrollerContainer.width = this.userListScroller.width = 117;
			this.userListScrollerContainer.addElement(userListScroller);
			this.userListScroller.percentHeight = 100;			
			this.userListScrollerContainer.top = TOP_MENU_SPACING;
			this.userListScrollerContainer.bottom = 10;
			this.userListScroller.viewport = userList;	
			this.userListScrollerContainer.x = USER_LIST_X;
			this.userListScrollerContainer.addElement(userListScroller);
			this.mainLayer.addElement(userListScrollerContainer);
			
			this.titleAndCamGrid.top = TOP_MENU_SPACING;
			this.titleAndCamGrid.left = this.topMenu.top = this.topMenu.left = 6
			this.titleAndCamGrid.bottom = 0;
			
			this.titleBar.gap = 1;
		}
		
		public function resize():void {
			this.height = this.mainLayer.height = this.master.height;
			if(this.master.width > this.minWidth) {
				this.width = this.master.width;
//				this.publicChatScrollerContainer.width = this.textChatInput.width = this.publicChatScrollerContainer.minWidth + this.width - this.minWidth;
				if(this.chat != null) this.chat.width = this.chat.minWidth + this.width - this.minWidth;
//				trace('master.width:'+this.master.width + ' this.minWidth:'+ this.minWidth + ' this.width:'+this.width);
			}
			if(popupCanvas != null) {
				this.popupCanvas.height = this.popupCanvas.canvas.height = this.master.height;
				this.popupCanvas.width = this.popupCanvas.canvas.width = this.master.width;								
			}
		}
		
		public function getName():String {
			return this.name;
		}
		
		public function getPassword():String {
			return this.password;
		}
		
		// given opts.id or opts.name and possibly opts.state, attempt
		// to get the wall attributes
		public function init(opts:Object):void {
			this.state = 0; // reset
			this.objects = new Object;
			peers = new Object;
			if(opts.state != undefined) this.state = opts.state; // initial state if successful
			opts.ban_check_user_id = user.userID;
			opts.joining = true;
			refreshAttributes(opts);
			gameWindow.getServerTime();
		}
		
		private function refreshAttributes(opts:Object):void {
			// name or id is required
			var variables:URLVariables = new URLVariables;
			if(opts.id != undefined) variables.id = opts.id;
			if(opts.name != undefined) variables.name = opts.name;
			if(opts.joining != undefined) {
				if(opts.ban_check_user_id != undefined) variables.ban_check_user_id = opts.ban_check_user_id;
				variables.joining = true;
			}
			var request:URLRequest = new URLRequest(CONFIG.SITE_URL + "/get_wall_attributes.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;

			this.loaders['refresh_attributes'] = new URLLoader;
			this.loaders['refresh_attributes'].addEventListener(Event.COMPLETE, handleRefreshAttributes);
			try {
				this.loaders['refresh_attributes'].load(request);
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}	
		}
		
		private function handleRefreshAttributes(e:Event):void {
			var response:Object = new Object;

			if(this.loaders['refresh_attributes'].data == null) {
				trace('null result in handleRefreshAttributes');
				return;
			}

			try {
				response = JSON.decode(this.loaders['refresh_attributes'].data);
			} catch (err:JSONParseError) {
				trace(err.getStackTrace());
			}
		
			if(response.success == '1') {
				
				// assign wall attributes
				for(var k:String in response.wall_attributes) {
					this[k] = response.wall_attributes[k];
				}				

				if(response.joining != undefined) {
					if(response.user_is_banned != undefined) {
						exit("You are banned from that room.", OOPS);
						return;
					} else {
						this.gotAttributes = true;
						init2(new Event(Event.COMPLETE));
					}
				}
				
				dispatchEvent(new Event(CustomEvent.ROOM_ATTRIBUTES_REFRESHED));
				
			} else {
				if(response.joining != undefined) {
					this.gotAttributes = false;
					exit(response.msg, OOPS);
				} else {
					Alert.show(response.msg, OOPS);
				}
			}
		}
		
		private function init2(e:Event):void {
			
			// Wall requires password?
			if(this.password.length == 0 || user.admin_for[this.id] != undefined) {
				init3(new Event(Event.COMPLETE));
				return;
			}

			// popup canvas for password input
			popupCanvas = new PopupCanvas(this);
			PopUpManager.addPopUp(popupCanvas, this, true);
			
			var password_form:VGroup = new VGroup;
			password_form.horizontalAlign = 'center';
			password_form.width = 600;
			password_form.gap = 20;
			password_form.paddingTop = password_form.paddingBottom = password_form.paddingRight = password_form.paddingLeft = 20;
			
			// title
			var titleBox:HGroup = new HGroup;
			var titleLabel:Label = new Label;
			titleLabel.text = this.getName();
			titleLabel.setStyle('fontSize', 30);
			titleLabel.setStyle('fontWeight', 'bold');
			titleLabel.setStyle('fontFamily', 'Arial');
			titleLabel.setStyle('color', 0xFFFFFF);
			password_form.addElement(titleLabel);
			
			// message
			var passPromptMsg:RichText = new RichText;
			passPromptMsg.text = 'Type the magic word.';
			passPromptMsg.setStyle('fontSize',20);
			passPromptMsg.setStyle('fontWeight', 'bold');
			passPromptMsg.setStyle('fontFamily', 'Arial');

			passPromptMsg.setStyle('color', 0xFFFFFF);
			password_form.addElement(passPromptMsg);
			
			// password request field
			passPromptInput.id = 'password_prompt_input';
			passPromptInput.setStyle("fontSize", 25);
			passPromptInput.displayAsPassword = true;
			passPromptInput.setStyle('paddingTop', 10);
			passPromptInput.setStyle('paddingBottom', 10);
			passPromptInput.setStyle('paddingRight', 10);
			passPromptInput.setStyle('paddingLeft', 10);
			passPromptInput.setStyle('textAlign', 'center');
			passPromptInput.addEventListener(FlexEvent.ENTER, checkPassword);
			passPromptInput.addEventListener(FlexEvent.CREATION_COMPLETE, creationCompleteHandler);
			password_form.addElement(passPromptInput);
			
			var password_buttons:HGroup = new HGroup;			
			password_buttons.gap = 10;
			password_buttons.paddingTop = 10;

			// password submit button
			passPromptSubmit.label = 'OK';
			passPromptSubmit.x = 260;
			passPromptSubmit.y = 50 + passPromptMsg.height;
			passPromptSubmit.height = 60;
			passPromptSubmit.width = 150;
			passPromptSubmit.addEventListener(MouseEvent.CLICK, checkPassword);
			password_buttons.addElement(passPromptSubmit);
			
			// password cancel button
			var passPromptCancel:Button = new Button;
			passPromptCancel.label = 'Cancel';
			passPromptCancel.x = 270 + passPromptSubmit.width;
			passPromptCancel.y = 50 + passPromptMsg.height;
			passPromptCancel.height = 60;
			passPromptCancel.width = 150;
			passPromptCancel.addEventListener(MouseEvent.CLICK, exitHandler);
			password_buttons.addElement(passPromptCancel);			
			password_form.addElement(password_buttons);
			
			popupCanvas.add(password_form);			
		}
		
		private function creationCompleteHandler(e:FlexEvent):void {
			if(e.target.id == 'password_prompt_input') passPromptInput.setFocus();			
		}
		
		private function checkPassword(e:Event):void {
			PopUpManager.removePopUp(popupCanvas);
			// password correct?
			if(this.password == HMAC.hash(CONFIG.HASH_KEY, passPromptInput.text, MD5)) {
				init3(new Event(Event.COMPLETE));
			} else {	// prompt for password again
				init2(new Event(Event.COMPLETE));
				Alert.show('Wrong password.', OOPS);
			}
		}
		
		public function init3(e:Event):void {
			try {
				if(this.gotAttributes) {
					init4();
				}
			} catch (e:TypeError) {
				trace("Could not initialize wall." + e.getStackTrace());
			}	
		}
		
		private function init4():void {
			PopUpManager.removePopUp(popupCanvas);				
			if(popupCanvas.numElements > 0) popupCanvas.removeAllElements();
			this.connect();
			createTopMenu();
			
			// Create room address link that appears above title/banner.
			this.room_address_label.text = 'http://' + this.url_name + '.' + this.CONFIG.DOMAIN;
			this.room_address_label.setStyle('fontSize', 10);
			this.room_address_label.setStyle('fontFamily', 'Arial');
			this.room_address_label.setStyle('color', 0x444444);
			this.room_address_copy.text = 'Copy Link';
			this.room_address_copy.height = 12;
			this.room_address_copy.setStyle('color', 0x444444);
			this.room_address_copy.setStyle('textDecoration', 'underline');
			this.room_address_copy.buttonMode = true;
			this.room_address_copy.useHandCursor = true;
			this.room_address_copy.addEventListener(MouseEvent.CLICK, copyRoomAddress);
			this.room_address_copy.setStyle('fontSize', 10);
			this.room_address_group.addElement(room_address_label);
			this.room_address_group.addElement(room_address_copy);
			
			createTitleBar();
			
			// set up the chat area
			this.chat = new Chat(this);
			this.chat.top = TOP_MENU_SPACING;
			this.chat.bottom = 10;
			this.chat.x = 785;
			this.chat.width = this.chat.minWidth = 275;
			this.mainLayer.addElement(this.chat);
			
			// Layout is complete. Size it by browser width.
			this.resize();
		}
		
		// Room address copy link clicked.
		private function copyRoomAddress(e:MouseEvent):void {
			flash.system.System.setClipboard('http://' + this.url_name + '.' + CONFIG.DOMAIN);
			setTimeout(showCopyRoomAddressLink, 8000);
			this.room_address_copy.alpha = 0;
		}
		
		// After it has been clicked, show it again.
		private function showCopyRoomAddressLink():void {
			this.room_address_copy.alpha = 1;
		}
		
		// turn the wall's games on
		private function wallGamesOn():void {
			this.game_on = 1;
			gameWindow.init();
			showPlayButton();
			gameWindow.showGameWindow(new MouseEvent(MouseEvent.CLICK));
		}
		
		// Turn games off for this user.
		private function wallGamesOff():void {
			this.game_on = 0;
			PopUpManager.removePopUp(gameWindow);
			gameWindow.clearGameTimers();
			gameWindow.gameContent.removeAllElements();
			hidePlayButton();
		}
		
		// creates the title name or banner image
		private function createTitleBar():void {
			if(titleBar.numElements > 0) titleBar.removeAllElements();
			
			if(titleBar.contains(room_address_group) == false) {
				this.titleBar.addElement(this.room_address_group);					
			}
			
			// room text name or banner
			if(this.creator_user_id > 0 && this.banner_file_id == 0) {

				if(titleBar.contains(wallNameLabel) == false) {
					this.wallNameLabel.text = this.name;
					this.wallNameLabel.setStyle('fontSize',25);
					this.wallNameLabel.maxWidth = 400;
					titleBar.addElement(wallNameLabel);
				}		
				
			} else {	// download the banner file
				var request:URLRequest;
				if(this.creator_user_id > 0) request = new URLRequest(this.CONFIG.SITE_URL + '/files/' + this.banner_file_name);
				else request = new URLRequest(this.CONFIG.SITE_URL + '/facebook_invite_banner.gif');
				loaders['getBanner'] = new URLLoader;
				loaders['getBanner'].dataFormat = URLLoaderDataFormat.BINARY;
				loaders['getBanner'].addEventListener(Event.COMPLETE, createTitleBannerHandler1);
				loaders['getBanner'].addEventListener(IOErrorEvent.IO_ERROR, ioEventHandler);
				loaders['getBanner'].addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityEventHandler);

				try {
					(loaders['getBanner'] as URLLoader).load(request);
				} catch (error:SecurityError) {
					trace(error.getStackTrace());
				} catch (error:IOError) {
					trace(error.getStackTrace());
				}
			}
		}
		
		private function ioEventHandler(e:IOErrorEvent):void {
			trace(e.type);
		}
		
		private function securityEventHandler(e:SecurityErrorEvent):void {
			trace(e.type);
		}
		
		private function createTitleBannerHandler1(e:Event):void {
			loaders['getBanner'].removeEventListener(Event.COMPLETE, createTitleBannerHandler1);
			loaders['getBannerLoader'] = new Loader;
			loaders['getBannerLoader'].contentLoaderInfo.addEventListener(Event.COMPLETE, createTitleBannerHandler2);
			(loaders['getBannerLoader'] as Loader).loadBytes((loaders['getBanner'] as URLLoader).data);
		}
		
		private function createTitleBannerHandler2(e:Event):void {
			this.banner = loaders['getBannerLoader'];
			createTitleBanner(loaders['getBannerLoader']);
			dispatchEvent(new CustomEvent(CustomEvent.BANNER_RETRIEVED));			
		}
		
		// add the banner
		private function createTitleBanner(banner:DisplayObject):void {
			if(bannerContainer != null && titleBar.contains(bannerContainer) == true) titleBar.removeElement(bannerContainer);

			bannerContainer = new UIComponent;
			
			// set dimensions
			banner.width = BANNER_WIDTH;
			banner.height = BANNER_HEIGHT;
			bannerContainer.height = banner.height;
			bannerContainer.width = banner.width;
			
			// update status message when clicked in order to invite other people
			if(this.creator_user_id == 0 && this.banner_file_id == 0) {
				bannerContainer.addEventListener(MouseEvent.CLICK, doInviteByStatus);
				bannerContainer.buttonMode = true;
				bannerContainer.useHandCursor = true;
			}

			bannerContainer.addChild(banner);
			titleBar.addElement(bannerContainer);
		}
		
		// update user's status to invite people to current room
		private function doInviteByStatus(e:MouseEvent):void {
			Facebook.postData('/me/feed', doInviteByStatusHandler, {'message':"Join me on Everchat at http://" + this.url_name + '.' + CONFIG.DOMAIN, 'link':'http://' + this.url_name + '.' + CONFIG.DOMAIN, 'picture':'http://' + CONFIG.DOMAIN + '/everchat_fb.png', 'description':'Everchat is a Facebook-only chat room with multiplayer trivia'});

			// animate away the banner 
			var a:Animate = new Animate;
			var s:SimpleMotionPath = new SimpleMotionPath('alpha', 1, 0.7);
			a.motionPaths = new Vector.<MotionPath>;
			a.motionPaths.push(s);
			a.target = banner;
			a.repeatBehavior = 'reverse';
			a.repeatCount = 10;
			a.duration = 100;
			a.addEventListener(EffectEvent.EFFECT_END, clearTitleBar1);
			a.play();
		}
		
		private function clearTitleBar1(e:Event):void {
			// animate away the banner 
			var a:Animate = new Animate;
			var s1:SimpleMotionPath = new SimpleMotionPath('height', banner.height, 0);
			a.motionPaths = new Vector.<MotionPath>;
			a.motionPaths.push(s1);
			a.target = banner;
			a.duration = 500;
			a.addEventListener(EffectEvent.EFFECT_END, clearTitleBar2);
			a.play();
			
			// animate away the banner 
			var b:Animate = new Animate;
			var s2:SimpleMotionPath = new SimpleMotionPath('alpha', bannerContainer.height, 0);
			b.motionPaths = new Vector.<MotionPath>;
			b.motionPaths.push(s2);
			b.target = bannerContainer;
			b.duration = 500;
			b.play();
			
		}
		
		private function clearTitleBar2(e:Event):void {
			titleBar.removeAllElements();
		}
				
		// log into local site
		private function doInviteByStatusHandler(result:Object,fail:Object):void {
		}
		
		private function createTopMenu():void {
			
			// add logo
			if(topMenu.contains(logoContainer) == false) {
				logoBitmap = new logo();
				logoContainer.height = logoBitmap.height;
				logoContainer.width = logoBitmap.width;
				topMenu.addElement(logoContainer);
				if(logoContainer.numChildren > 0) logoContainer.removeChildAt(0);
				logoContainer.addChild(logoBitmap);
				logoContainer.addEventListener(MouseEvent.CLICK, exitHandler);
				logoContainer.buttonMode = logoContainer.useHandCursor = true;				
			}
			
			if(topMenu.contains(inviteButton) == false) {
				inviteButton.label = 'Invite Friends';
				inviteButton.toolTip = "Get a link to give other people";
				inviteButton.addEventListener(MouseEvent.CLICK, handleInviteFriends);
				topMenu.addElement(inviteButton);
			}
			
			// put the add camera button on there
			if(topMenu.contains(addCameraButton) == false) {	
				addCameraButton.label = 'Start Webcam';
				addCameraButton.toolTip = 'Broadcast your webcam and gain ability to talk to the room';
				addCameraButton.addEventListener(MouseEvent.CLICK, addCamera);
				topMenu.addElement(addCameraButton);
			}
			
			// put the push to talk button on there
			if(topMenu.contains(pushToTalkButton) == false) {	
				pushToTalkButton.label = 'Push to Talk';
				pushToTalkButton.addEventListener(MouseEvent.MOUSE_DOWN, talk);
				pushToTalkButton.addEventListener(MouseEvent.MOUSE_UP, talk);
				topMenu.addElement(pushToTalkButton);
				pushToTalkButton.toolTip = "PLEASE WEAR HEADPHONES TO PREVENT FEEDBACK. Talk to the room by holding this button down. Your webcam must be on.";
			}
			
			// put the admin button on there if user is admin
			if(this.user.admin_for[this.id] != undefined) showAdminButton();
			
			// only show the favorites button if logged in
			if(topMenu.contains(faveButton) == false) {	
				if(this.user.favewalls[this.id] != undefined) faveButton.label = '- Favorite';
				else faveButton.label = '+ Favorite';
				faveButton.addEventListener(MouseEvent.CLICK, handleFave);
				faveButton.toolTip = 'Add (+) or remove (-) room from favorites';
				topMenu.addElement(faveButton);
			}
			
			// put the exit button on there
			if(topMenu.contains(exitButton) == false) {	
				exitButton.label = 'X';
				exitButton.addEventListener(MouseEvent.CLICK, exitHandler);
				exitButton.width = 50;
				topMenu.addElement(exitButton);	
			}
			
			if(mainLayer.contains(topMenu) == false) {
				mainLayer.addElement(topMenu);
			}
			
			topMenu.width = this.width - wallNameLabel.width - 425;			
		}
		
		private function talk(e:MouseEvent):void {
			if(mic != null) {
//				if(e.type == 'mouseDown') mic.setSilenceLevel(10);
//				if(e.type == 'mouseUp') mic.setSilenceLevel(100);
				if(e.type == 'mouseDown') {
					mic.setSilenceLevel(10);
					camGrid.camWindows[myCamIndex].videoStream.attachAudio(mic);
				}
				if(e.type == 'mouseUp')	camGrid.camWindows[myCamIndex].videoStream.attachAudio(null);
			}
		}
		
		// put play game button in the main menu. this button just shows the game window if it was closed
		// as opposed to starting the game up from scratch
		private function showPlayButton():void {
			// play game button
			if(topMenu.contains(playButton) == false) {
				playButton.label = 'Play Game';
				playButton.addEventListener(MouseEvent.CLICK, gameWindow.showGameWindow);
				playButton.toolTip = 'Show the game window';
				topMenu.addElementAt(playButton, topMenu.numElements-1);
			}
		}
		
		// remove play game button from main menu
		private function hidePlayButton():void {
			if(topMenu.contains(playButton)) {
				topMenu.removeElement(playButton);
			}
		}
		
		// add admin button to main menu
		private function showAdminButton():void {
			if(topMenu.contains(settingsButton) == false) {
				settingsButton.label = 'Administration';
				settingsButton.addEventListener(MouseEvent.CLICK, showAdminScreenHandler);
				settingsButton.toolTip = this.getName() + ' settings';
				topMenu.addElementAt(settingsButton, topMenu.numElements-1);
			}
		}
		
		// remove admin button from main menu
		private function hideAdminButton():void {
			if(topMenu.contains(settingsButton)) {
				topMenu.removeElement(settingsButton);
			}
		}
						
		private function connect():void {			
			netConnection = new NetConnection();
			netConnection.addEventListener(NetStatusEvent.NET_STATUS, netStatus);
			netConnection.connect(SERVER+DEVKEY);
		}
		
		private function handleFave(e:MouseEvent):void {
			var variables:URLVariables = new URLVariables;
			variables.wall_id = this.id;
			variables.wall_name = this.name;
			variables.url_name = this.url_name;
			variables.email = this.user.email;
			if(faveButton.label == '+ Favorite') {
				variables.action = 1;
			} else {
				variables.action = 0;				
			}
			var request:URLRequest = new URLRequest(CONFIG.SITE_URL + "/favewall.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;
			loader = new URLLoader;
			loader.addEventListener(Event.COMPLETE, finishFave);
			//loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			try {
				loader.load(request);
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}
		}
		
		// add to favorites request finished
		public function finishFave(e:Event):void {
			var response:Object;
			response = JSON.decode(loader.data);
			if(response.success == '1') {
				// do successful stuff
				if(faveButton.label == '- Favorite') {
					delete this.user.favewalls[this.id];
					faveButton.label = '+ Favorite';
//					Alert.show(this.name + ' has been removed from your favorites.', 'Good Job');
				} else {
					this.user.favewalls[this.id] = {'name':this.getName(), 'num_members':this.netGroup.estimatedMemberCount};
					faveButton.label = '- Favorite';	
//					Alert.show(this.name + ' has been added to your favorites.', 'Good Job');
				}			
			} else {
				// do unsuccessful stuff
				Alert.show('There was a problem doing that.', OOPS);
			}
		}
		
		private function handleInviteFriends(e:MouseEvent):void {
			
			var column:VGroup = new VGroup;
			column.gap = 20;
			column.paddingBottom = column.paddingTop = column.paddingLeft = column.paddingRight = 20;
			
			var inviteFriendsMsg:Text = new Text;			
			inviteFriendsMsg.htmlText = 'Give your friends this address:';
			inviteFriendsMsg.setStyle('fontSize',20);
			inviteFriendsMsg.setStyle('fontFamily', 'Arial');
			inviteFriendsMsg.selectable = false;
			inviteFriendsMsg.setStyle('color', 0xFFFFFF);
			column.addElement(inviteFriendsMsg);

			var inviteFriendsMsg2:Text = new Text;
			inviteFriendsMsg2.text = 'http://' + this.url_name + '.' + CONFIG.DOMAIN;
			flash.system.System.setClipboard('http://' + this.url_name + '.' + CONFIG.DOMAIN);
			inviteFriendsMsg2.setStyle('fontSize',33);
			inviteFriendsMsg2.selectable = true;
			inviteFriendsMsg2.setStyle('fontWeight', 'bold');
			inviteFriendsMsg2.setStyle('fontFamily', 'Courier New');
			inviteFriendsMsg2.setStyle('color', 0xFFFFFF);
			column.addElement(inviteFriendsMsg2);

			var inviteFriendsMsg3:Text = new Text;
			inviteFriendsMsg3.text = 'The link has been copied to your clipboard. You can Ctrl-V into an email now.';
			inviteFriendsMsg3.setStyle('fontSize',20);
			inviteFriendsMsg3.setStyle('fontFamily', 'Arial');
			inviteFriendsMsg3.selectable = false;
			inviteFriendsMsg3.setStyle('color', 0xFFFFFF);
			column.addElement(inviteFriendsMsg3);
			
			// game on checkbox
			inviteFacebookCheckbox.label = 'Post to Facebook that you are in this room.';
			inviteFacebookCheckbox.selected = false;
			inviteFacebookCheckbox.setStyle('fontSize',20);
			inviteFacebookCheckbox.setStyle('fontFamily', 'Arial');
			inviteFacebookCheckbox.setStyle('color', 0xFFFFFF);
			column.addElement(inviteFacebookCheckbox);
						
			// username submit button
			inviteFriendsCloseButton.label = 'OK';
			inviteFriendsCloseButton.height = 60;
			inviteFriendsCloseButton.width = 150;
			inviteFriendsCloseButton.addEventListener(MouseEvent.CLICK, handleCloseInviteFriends);
			column.addElement(inviteFriendsCloseButton);
			
			popupCanvas = new PopupCanvas(this);
			PopUpManager.addPopUp(popupCanvas, this, true);			
			popupCanvas.add(column);			
		}
		
		// Close the invite screen.
		private function handleCloseInviteFriends(e:MouseEvent):void {
			PopUpManager.removePopUp(popupCanvas);
			if(inviteFacebookCheckbox.selected) Facebook.postData('/me/feed', invitePostHandler, {'message':"Join me on Everchat at http://" + this.url_name + '.' + CONFIG.DOMAIN, 'link':'http://' + this.url_name + '.' + CONFIG.DOMAIN, 'picture':'http://' + CONFIG.DOMAIN + '/everchat_fb.png', 'description':'Everchat is a Facebook-only chat room with multiplayer trivia'});
		}
		
		// Callback for the invite screen if a Facebook status update was performed.
		private function invitePostHandler(result:Object,fail:Object):void {}
		
		private function exitHandler(event:MouseEvent):void { exit(); }
		
		private function exit(msg:String='', msg_title:String=''):void {
			if(msg.length > 0) {
				Alert.show(msg, msg_title);
				if(msg_title == OOPS) {
					var error_sound:SoundAsset = new this.master.error_sound() as SoundAsset; 
					var error_sound_channel:SoundChannel = error_sound.play(); 
				}
			}
			
			// clear game
			gameWindow.clearGameForExit();
						
			this.want_objects_requested = false;

			// clear checkForTalk timer
			clearInterval(checkForTalkTimer);
			
			// Stop reporting estimated member count to server.
			clearInterval(reportEstimatedMembersInterval);
			
			// Clear Chat object.
			if(this.chat != null) {
				this.chat.exit();
				if(this.mainLayer.contains(this.chat)) this.mainLayer.removeElement(this.chat);
			}
			
			this.id = '';	// unset attribute			
			
			this.password = '';
			topMenu.removeAllElements();
			titleBar.removeAllElements();			// titleBar is recreated upon wall entry
			this.userList.removeAllElements();
			clearAdminStuff();	// remove admin options (user could join another wall where s/he is not admin
			for(var i:int=0; i<camGrid.camWindows.length; i++) {
				if(i == myCamIndex) {
					removeMyCam();
				}
				if(camGrid.camWindows[i] != undefined) {
					camGrid.camWindows[i].videoStream.close();
					camGrid.camWindows[i].video.clear();
					this.camGrid.removeCam(camGrid.camWindows[i]);
					delete camGrid.camWindows[i];
				}
			}
			
			myCamIndex = -1;
			if(netGroup != null && netConnection.connected) {
				netGroup.close();		
				netConnection.close();
			}
			PopUpManager.removePopUp(popupCanvas);
			gameWindow.removeAllElements();
			this.master.removeElement(this);
			this.master.enterHome();
		}
		
		// stop and remove local user's camera from the video wall
		private function removeMyCam():void {
			camGrid.camWindows[myCamIndex].videoStream.close();
			camGrid.camWindows[myCamIndex].video.attachNetStream(null);
			camGrid.camWindows[myCamIndex].videoStream.attachCamera(null);
			camGrid.camWindows[myCamIndex].videoStream.attachAudio(null);
			this.camGrid.removeCam(camGrid.camWindows[myCamIndex]);
			mic = null;
			myCamIndex = -1;
			delete camGrid.camWindows[myCamIndex];
		}
		
		private function groupConnect():void {
			groupspec = new GroupSpecifier(this.id);
			groupspec.serverChannelEnabled = true;
			groupspec.multicastEnabled = true;
			groupspec.postingEnabled = true;
			groupspec.objectReplicationEnabled = true;

			netGroup = new NetGroup(netConnection,groupspec.groupspecWithoutAuthorizations());
			netGroup.addEventListener(NetStatusEvent.NET_STATUS,netStatus);
			
			reportEstimatedMembersInterval = setInterval(reportEstimatedMembers, 180000);
		}
		
		private function reportEstimatedMembers():void {
			if(this.isSeeder() && netConnection.connected == true) {
				var variables:URLVariables = new URLVariables;
				
				variables.room_id = this.id;
				variables.num_members = netGroup.estimatedMemberCount;
				
				var request:URLRequest = new URLRequest(this.CONFIG.SITE_URL + "/report_estimated_members.php");
				request.method = URLRequestMethod.POST;
				request.data = variables;
				
				loaders['report_estimated_members'] = new URLLoader;
				loaders['report_estimated_members'].addEventListener(IOErrorEvent.IO_ERROR, ioEventHandler);
				loaders['report_estimated_members'].addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityEventHandler);
				
				try {
					loaders['report_estimated_members'].load(request);
				} catch (err:IOErrorEvent) {
					trace(err.type);
				} catch (err:SecurityError) {
					trace(err.getStackTrace());				
				}
			}
		}
		
		public function setup():void {
			netGroup.replicationStrategy = NetGroupReplicationStrategy.LOWEST_FIRST;

			// want all objects
			if(this.want_objects_requested == false) {
				netGroup.addWantObjects(last_started_game_object_id, 9007199254740992);		// 9007199254740992 is the exact max
				this.want_objects_requested = true;
			}
			
			// every 1.5 seconds, check if a person with a camera is talking
			checkForTalkTimer = setInterval(checkForTalk, 1500);

			// go into admin screen if room was just created
			if(this.state == 1) {
				this.showAdminScreen();
				adminify();
			}
			
			// turn games on in 4 seconds if they are turned on for this room
			if(this.game_on == 1) {
				joinGame();
			}
			
			// adminify this user if s/he is admin
			if(this.user.admin_for[this.id] != undefined && this.user.admin_for[this.id] == true || user.userID == 1) {
				adminify();
			}
		}
		
		private function joinGame():void {
			wallGamesOn();
			if(netConnection.connected && seedGame() == false) {	// if there are other players 
				this.gameWindow.getGame();
			}
		}
		
		// process new object 
		public function processNewObject(object_id:int, obj:Object):void {

			try {
				if(obj == null) throw new Error('processNewObject() says obj argument is null.');
			} catch (error:Error) {
				trace(error.message);
				return;
			}
			var i:int = 0;	// general purpose counter
			var k:String; 	// general purpose index
			
			// assign new object
			this.objects[object_id] = obj;

			netGroup.removeWantObjects(object_id, object_id);
			netGroup.addHaveObjects(object_id, object_id);

			if(this.objects[object_id].type != undefined) {

				if(this.objects[object_id].type == 'start game') {
					var d:Date = new Date();
					if( ((Number(this.objects[object_id].activated_time) + this.objects[object_id].wait_time) - (d.getTime() + this.gameWindow.serverTimeOffset)) < 0 ) return;

					// only try to start the game if that game object exists && it is not already started
					if(this.objects[obj.game_to_start_object_id] != undefined && this.gameWindow.game.id != this.objects[obj.game_to_start_object_id].id) {				
						
						this.objects[obj.game_to_start_object_id].activated_time = obj.activated_time;
						gameWindow.startGame(obj.game_to_start_object_id);
					}

				// start wall games
				} else if(this.objects[object_id].type == 'games on' && this.game_on == 0) {
					joinGame();

				// stop wall games
				} else if(this.objects[object_id].type == 'games off' && this.game_on == 1) {
					wallGamesOff();

				// the round info is displayed during intermission
				} else if(this.objects[object_id].type == 'round' && gameWindow.gameContent.contains(gameWindow.roundData) == false) {

					this.gameWindow.handleRoundData(this.objects[object_id]);
					
				} else if(this.objects[object_id].type == 'game') {

					initGameObject(object_id);

					// attempt to start the current game (probably won't be successful, but this gets the timers going)
				} else if(this.objects[object_id].type == 'current game') {
					
					initGameObject(object_id);
					gameWindow.startGame(object_id);

				} else if(this.objects[object_id].type == 'chunk') {

				// tell the room there is a new banner. only a seeder will react to the message.
				} else if(this.objects[object_id].type == 'seed room banner') {
					if(this.banner_last_object_id >= this.objects[object_id].end_object_id) return;
					
					if(this.isSeeder()) {
trace('banner_shared_object_index:'+banner_shared_object_index);
/*
						// track the last used banner object_id for sequential control issues
						if(this.objects[object_id].end_object_id < banner_last_object_id) return;
						else {
							this.banner_last_object_id = this.objects[object_id].end_object_id;
						}
*/						
						this.banner_shared_object_index = sharedObjects.length;
						sharedObjects[banner_shared_object_index] = new P2PSharedObject;
						sharedObjects[banner_shared_object_index].type = 'banner';
						sharedObjects[banner_shared_object_index].sharedObjectsIndex = banner_shared_object_index;
						sharedObjects[banner_shared_object_index].start_object_id = this.objects[object_id].start_object_id;
						sharedObjects[banner_shared_object_index].end_object_id = this.objects[object_id].end_object_id;
						sharedObjects[banner_shared_object_index].banner_file_id = this.objects[object_id].banner_file_id;
						sharedObjects[banner_shared_object_index].addEventListener(Event.COMPLETE, shareFileObject);
						shareNewBanner1();
					}
					
				// this is a chunk of a new room banner
				} else if(this.objects[object_id].type == 'room banner chunk') {
//trace(this.objects[object_id].type + ' object_id:'+ object_id + ' start_id:'+this.objects[object_id].start_object_id+ ' end_id'+this.objects[object_id].end_object_id + ' banner_file_id:'+this.objects[object_id].banner_file_id+ ' this bfid:'+this.banner_file_id);

					// only consider new banners
					if(this.objects[object_id].banner_file_id <= this.banner_file_id) return;
					if(this.banner_last_object_id > this.objects[object_id].end_object_id) return;

					// attempt to put it together
					for(var j:Number = Number(this.objects[object_id].start_object_id); j <= Number(this.objects[object_id].end_object_id); j++) {
						if(this.objects[j] == undefined) {
							trace('room banner not ready object_id:'+j);
							return;
						}						
					}

					// all chunks exist. create and add the banner.
					var bannerBytes:ByteArray = new ByteArray;
					for(j = Number(this.objects[object_id].start_object_id); j <= Number(this.objects[object_id].end_object_id); j++) {
						bannerBytes.writeBytes(this.objects[j].data);
					}
					var bannerLoader:Loader = new Loader;								
					bannerLoader.loadBytes(bannerBytes);
					bannerLoader.contentLoaderInfo.addEventListener(Event.COMPLETE, displaySharedBanner);
					this.banner_file_id = this.objects[object_id].banner_file_id;
					this.banner_last_object_id = this.objects[object_id].end_object_id;
				
				} else if(this.objects[object_id].type == 'clear room banner') {
					if(this.banner_last_object_id < object_id) {
						this.banner_file_id = 0;
						this.createTitleBar();
					}
				}
			}
		}
		
		// a shared banner is ready to be displayed
		private function displaySharedBanner(e:Event):void {
			var bannerImg:Bitmap = new Bitmap;
			bannerImg = e.target.content
			this.createTitleBanner(bannerImg);
		}

		// initiates some game object members 
		private function initGameObject(object_id:int):void {
			if(int(this.objects[object_id].data.num_files) > 0) {
				
				// there are files, so create files object
				this.objects[object_id].files = new Object;
				
				// each file is a ByteArray
				for(var i:int = 0; i < this.objects[object_id].data.num_files; i++) {
					this.objects[object_id].files[i] = new ByteArray;
				}
			}
			
			// seed the game
			if(this.user.is_game_seeder && int(this.objects[object_id].data.num_files) > 0) {
				for(i = 0; i < this.objects[object_id].data.num_files; i++) {
					var index:int = sharedObjects.length;
					sharedObjects[index] = new P2PSharedObject;
					sharedObjects[index].type = 'game';
					sharedObjects[index].sharedObjectsIndex = index;
					sharedObjects[index].setGameObjectID(object_id);
					sharedObjects[index].setMeta(this.objects[object_id].data.files_meta[i]);
					sharedObjects[index].addEventListener(Event.COMPLETE, shareFileObject);
					sharedObjects[index].downloadFile();
				}
			}
		}
		
		// loop through P2PSharedObject's chunks and share them
		private function shareFileObject(e:Event):void {
			for(var k:String in e.target.chunks) {
				this.objects[e.target.chunks[k].object_id] = e.target.chunks[k];						// save chunk for seeder
				if(netConnection.connected) netGroup.addHaveObjects(e.target.chunks[k].object_id, e.target.chunks[k].object_id);	// offer chunk to group
			}

			sharedObjects[e.target.sharedObjectsIndex].removeEventListener(Event.COMPLETE, shareFileObject);
			delete sharedObjects[e.target.sharedObjectsIndex];
		}
		
		// determine number of seeders
		public function getNumSeeders():uint {
			if(this.peersArray.length <= 10) {
				return 2;
			} else if(this.peersArray.length <= 50) {
				return Math.ceil(0.15 * this.peersArray.length);
			} else {
				return 8;
			}
		}
		
		/**
		 * Returns zero (not a seeder) or the seeder's position in the list of seeders.
		 */
		public function isSeeder():uint {
			var numSeeders:int = this.getNumSeeders();
			var seederPosition:uint = 0;	// position of the current user in the list of seeders
			for(var k:String in peersArray) {
				if(peersArray[k] != undefined && peersArray[k].peerID == netConnection.nearID) {	// this user is a seeder
					seederPosition++;
					break;
				}
				if(peersArray[k].connected) seederPosition++;
				if(seederPosition == numSeeders) break;
			}
			if(peersArray[k].peerID == netConnection.nearID) {
				this.user.is_game_seeder = true;
				return seederPosition;	
			} else {
				this.user.is_game_seeder = false;
				return 0;
			} 
		}

		// if the user is a seeder, propogate the game files
		public function seedGame():Boolean {

			if(this.gameWindow.seedGameTimer) clearInterval(this.gameWindow.seedGameTimer);
			this.gameWindow.seedGameTimer = setInterval(seedGame, 90000);
			
			var seederPosition:uint = this.isSeeder();

			if(seederPosition == 0) {			// is not a seeder
				return false;
			} else if(seederPosition > 0) {		// is a seeder
				gameWindow.seedTimer = setTimeout(this.gameWindow.getGame, (seederPosition-1)*2000);
				return true;
			} else {
				return false;
			}
		}
		
		private function submitUsername(e:Event):Boolean {
			init4();
			user['username'] = usernameInput.text;
			popupCanvas.del(usernameInput);
			popupCanvas.del(submitUsernameButton);
			return true;
		}

		private function netStatus(event:NetStatusEvent):void{
//trace('event.info.code:'+event.info.code);

			var camID:int;	// simplify some lines
			switch(event.info.code){
				
				case "NetConnection.Connect.Success":
					groupConnect();
					break;
				
				case "NetConnection.Connect.Closed":
					// if wall is still loaded, the connection was lost prematurely
					if(this.id.length > 0) { 
						exit("Lost internet connection!", OOPS);	
					}
					break;

				case "NetConnection.Connect.Failed":
					if(this.id.length > 0) exit("Are you connected to the internet?", OOPS);	// if wall is still loaded, call exit()
					break;
				
				case "NetConnection.Connect.Rejected":
					Alert.show(event.info.message, OOPS);
					break;
				
				case "NetGroup.Connect.Closed":
					if(netConnection.connected) netGroup.removeWantObjects(0, 9007199254740992);
					break;

				case "NetGroup.Connect.Success":
					broadcastUsername();
					setup();
					break;
				
				case "NetGroup.Posting.Notify":
					receiveMessage(event.info.message);
					break;
				
				case "NetGroup.Neighbor.Connect":
					if(peers[event.info.peerID] == undefined) initializePeer(event.info.peerID);
					peers[event.info.peerID].connected = true;
					broadcastUsername();
					break;
				
				// delete the neighbor if it never connected
				case "NetGroup.MulticastStream.UnpublishNotify":
					if(peers[event.info.name] != undefined) {
						camID = peers[event.info.name].camID;			// simplify next lines
						peers[event.info.name].camID = -1;				// no camera
						camGrid.camWindows[camID].videoStream.close();
						camGrid.camWindows[camID].video.clear();
						camGrid.camWindows[camID].removeEventListener(MouseEvent.CLICK, handleCamWindowClick);
						this.camGrid.removeCam(camGrid.camWindows[camID]);
						delete camGrid.camWindows[camID];
						if(peers[event.info.name].connected == false) removePeer(event.info.name);
					}
					break;
				
				// publish media window, but only if the neighbor exists (NetGroup.Neighbor.Connect has been called)
				// this stream might come before the NetGroup.Neighbor.Connect, so keep a list of the peerIDs
				// so that it is published when the neighbor connects
				// there is a chance that getNextAvailableCell() returns a -1. d
				case "NetGroup.MulticastStream.PublishNotify":

					if(peers[event.info.name] == undefined) initializePeer(event.info.name);
					camID = peers[event.info.name].camID = getNextAvailableCell(false);
					camGrid.camWindows[camID] = new CamWindow(VIDEO_CELL_W, VIDEO_CELL_H); // 11/17/2010
					camGrid.camWindows[camID].camID = camID;								// 11/17/2010
					camGrid.camWindows[camID].videoStream = new NetStream(netConnection,groupspec.groupspecWithoutAuthorizations());
					camGrid.camWindows[camID].videoStream.bufferTime = 0;
					camGrid.camWindows[camID].video.attachNetStream(camGrid.camWindows[camID].videoStream);	// attach to video object
					camGrid.camWindows[camID].videoStream.play(event.info.name);			// play the stream
					camGrid.camWindows[camID].user = peers[event.info.name];
					camGrid.camWindows[camID].pointsLabel.text = peers[event.info.name].points;
					camGrid.camWindows[camID].nameLabel.text = peers[event.info.name].username;
					camGrid.camWindows[camID].locationLabel.text = peers[event.info.name].location;
					camGrid.camWindows[camID].addEventListener(MouseEvent.CLICK, handleCamWindowClick);	// 11/17/2010
					if(this.user.admin_for[this.id] != undefined) {
						camGrid.camWindows[camID].kickButton.visible = true;
						camGrid.camWindows[camID].banButton.visible = true;
					}
					
					// add the CamWindow
					this.camGrid.addCam(camGrid.camWindows[camID]);	// 11/17/2010

					break;
				
				case "NetGroup.Neighbor.Disconnect":
					peers[event.info.peerID].connected = false;
					removePeer(event.info.peerID);						
					refreshUserList();
					break;
								
				case "NetGroup.Replication.Fetch.Result": // e.info.index, e.info.object
//trace(event.info.object.type);
					processNewObject(event.info.index, event.info.object);
					break;
				
				case "NetGroup.Replication.Request": // e.info.index, e.info.requestID
//trace('index:'+event.info.index, ' requestID:'+event.info.requestID, ' object:'+objects[event.info.index]);
					netGroup.writeRequestedObject(event.info.requestID, objects[event.info.index])
					break;

				case "NetGroup.SendTo.Notify":	// direct routing
					
					if(event.info.fromLocal == true) {
						trace("Received Message: " + event.info.message.value);
					} else {
						netGroup.sendToNearest(event.info.message, event.info.message.destination);
					}
					break;
			}
		}

		private function initializePeer(peerID:String):void {
			if(peers[peerID] == undefined) {
				peers[peerID] = new Object();			// save this neighbor
				peers[peerID].userID = 0;
				peers[peerID].points = 0;
				peers[peerID].location = '';
				peers[peerID].username = '';	
				peers[peerID].peerID = peerID;
				peers[peerID].facebook_id = '';
				peers[peerID].camID = -1;
				peers[peerID].connected = false;		// initial state
				peers[peerID].admin_for = new Array;
				var userListLabel:Label = new Label;
				userListLabel.maxDisplayedLines = 1;
				userListLabel.text = '';
				userListLabel.setStyle('fontFamily', 'Arial');
				userListLabel.setStyle('fontSize', 10);
				userListLabel.setStyle('color', 0x000000);
				userListLabel.width = userList.width;
				userListLabel.addEventListener(MouseEvent.CLICK, showUsersMenu);
				userListLabel.name = peerID;
				peers[peerID].userListLabel = userListLabel;
			}
		}
		
		private function showUsersMenu(e:MouseEvent):void {
			userListActionMenu.hide();
			if(netConnection.nearID != e.target.name) {
				//Create some XML to populate the menu  
				var myMenuData:XML =   
					<root>  
						<menuitem label={peers[e.target.name].username} enabled="false" />
						<menuitem label="msg" />
					</root>  
				myMenuData.appendChild(new XML('<menuitem label="flag" userID="'+peers[e.target.name].userID+'" />'));
				// admin functionality
				if(this.user.admin_for[this.id] == true) {
					myMenuData.appendChild(new XML('<menuitem label="kick" userID="'+peers[e.target.name].userID+'" />'));
					myMenuData.appendChild(new XML('<menuitem label="ban" userID="'+peers[e.target.name].userID+'" />'));
					if(peers[e.target.name].admin_for[this.id] == undefined) {
						myMenuData.appendChild(new XML('<menuitem label="make admin" userID="'+peers[e.target.name].userID+'" />'));						
					} else if(peers[e.target.name].userID != this.creator_user_id) { // is admin
						myMenuData.appendChild(new XML('<menuitem label="revoke admin" userID="'+peers[e.target.name].userID+'" />'));						
					}
				}
				userListActionMenu = Menu.createMenu(this, myMenuData, false);
				userListActionMenu.name = e.target.name;
				userListActionMenu.width = 120;
				userListActionMenu.labelField = "@label";
				userListActionMenu.setStyle('rollOverColor', 0x888888);
				userListActionMenu.setStyle('selectionColor', 0x888888);
				userListActionMenu.setStyle('textRollOverColor', 0xFFFFFF);
				userListActionMenu.setStyle('textSelectedColor', 0xFFFFFF);
				userListActionMenu.addEventListener(MenuEvent.ITEM_CLICK, usersMenuClickHandler);

				var point:Point = new Point;
				// Calculate position of Menu in Application's coordinates. 
				point.x = USER_LIST_X-120;
				point.y = e.target.y+5;
				//point = e.target.localToGlobal(point);
				
				userListActionMenu.show(point.x, point.y);
			}
		}

		// Event handler for the Menu control's change event.
		private function usersMenuClickHandler(e:MenuEvent):void  {
			var userID:int = parseInt(e.item.@userID.toString());
			var opts:Object;
			switch(e.item.@label.toString()) {
				case 'msg':
					pm(e.menu.name);
					break;
				case 'kick':
					kick(e.menu.name);
					break;
				case 'ban':
					ban(e.menu.name);
					break;
				case 'flag':
					flag(e.menu.name);
					break;
				case 'make admin':
					opts = new Object;
					opts = {peerID:e.menu.name, userID:userID};
					adminifyTarget(opts);
					break;
				case 'revoke admin':
					opts = new Object;
					opts = {peerID:e.menu.name, userID:userID};
					revokeTarget(opts);
					break;
			}
		}
		
		private function adminifyTarget(opts:Object):void {
			if(opts.userID) adminifySave(opts);
			// notify group
			var message:Object = new Object();
			message.type = 'make admin';
			message.peerID_to_adminify = opts.peerID;
			message.rand = Math.random().toString();
			netGroup.post(message);
			receiveMessage(message);
		}
		
		private function adminifySave(opts:Object):void {
			var variables:URLVariables = new URLVariables;
			variables.target_user_id = opts.userID;
			variables.wall_id = this.id;
			variables.wall_name = this.name;
			variables.url_name = this.url_name;
			var request:URLRequest = new URLRequest(CONFIG.SITE_URL + "/adminify.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;
			loader = new URLLoader;
			loader.addEventListener(Event.COMPLETE, adminifySaveHandler);
			//loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			try {
				loader.load(request);
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}					
		}
		
		private function adminifySaveHandler(event:Event):void{
			try {
				var response:Object = new Object;
				response = JSON.decode(loader.data);
				if(response.success == '1') {
					// do successful stuff
					Alert.show('User is now adminified.', 'Good Job');					
				} else {
					// do unsuccessful stuff
					Alert.show(response.msg, OOPS);					
				}
			} catch (e:TypeError) {
				trace("Could not adminify.");
			}				
		}

		private function revokeTarget(opts:Object):void {
			if(opts.userID) revokeSave(opts);
			// notify group
			var message:Object = new Object();
			message.type = 'revoke admin';
			message.peerID_to_revoke = opts.peerID;
			message.rand = Math.random().toString();
			netGroup.post(message);
			receiveMessage(message);
		}
		
		private function revokeSave(opts:Object):void {
			var variables:URLVariables = new URLVariables;
			variables.target_user_id = opts.userID;
			variables.wall_id = this.id;
			variables.wall_name = this.name;
			variables.url_name = this.url_name;
			var request:URLRequest = new URLRequest(CONFIG.SITE_URL + "/revoke.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;
			loader = new URLLoader;
			loader.addEventListener(Event.COMPLETE, revokeSaveHandler);
			//loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			try {
				loader.load(request);
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}					
		}
		
		private function revokeSaveHandler(event:Event):void{
			try {
				var response:Object = new Object;
				response = JSON.decode(loader.data);
				if(response.success == '1') {
					// do successful stuff
					Alert.show('Admin status revoked.', 'Good Job');					
				} else {
					// do unsuccessful stuff
					Alert.show(response.msg, OOPS);					
				}
			} catch (e:TypeError) {
				trace("Could not revoke admin status.");
			}				
		}		
		
		// post username to everyone in the group
		private function broadcastUsername():void{
			var message:Object = new Object();
			message.type = 'username';
			message.sender = netConnection.nearID;
			initializePeer(netConnection.nearID);
			message.username = peers[netConnection.nearID].userListLabel.text = this.user['username'];
			message.userID = this.user['userID'];
			message.points = this.user['points'];
			message.facebook_id = this.user['fbid'];
			message.location = this.user['location'];
			message.admin_for = this.user.admin_for;
			netGroup.post(message);
			receiveMessage(message);
		}
		
		// decide what to do when someone clicks a CamWindow
		private function handleCamWindowClick(event:MouseEvent):void {
			switch(event.target.name) {
				case "kickButton":
					// user will be null if it is the current user
					if(netConnection.nearID != event.currentTarget.user.peerID) {
						kick(event.currentTarget.user.peerID);
					}
					break;
				case "banButton":
					// user will be null if it is the current user
					if(netConnection.nearID != event.currentTarget.user.peerID) {
						ban(event.currentTarget.user.peerID);
					}
					break;
				case "flagButton":
					// user will be null if it is the current user
					if(netConnection.nearID != event.currentTarget.user.peerID) {
						flag(event.currentTarget.user.peerID);
					}
					break;
				case "muteButton":
					if(netConnection.nearID != event.currentTarget.user.peerID) {
						if(camGrid.camWindows[peers[event.currentTarget.user.peerID].camID].muteButton.text == 'M') {
							camGrid.camWindows[peers[event.currentTarget.user.peerID].camID].videoStream.soundTransform = new SoundTransform(0);	
							camGrid.camWindows[peers[event.currentTarget.user.peerID].camID].muteButton.text = 'Muted';
						} else {
							camGrid.camWindows[peers[event.currentTarget.user.peerID].camID].videoStream.soundTransform = new SoundTransform(1);
							camGrid.camWindows[peers[event.currentTarget.user.peerID].camID].muteButton.text = 'M';
						}
					}
					break;
				case "closeButton":
					if(netConnection.nearID != event.currentTarget.user.peerID) {
						camGrid.camWindows[peers[event.currentTarget.user.peerID].camID].hideVideo();
					} else { // remove my webcam
						removeMyCam();
					}
					break;
			}
		}	

		// Kick the user from the room.
		private function kick(id:String):void {
			var message:Object = new Object();
			message.type = 'kick';
			message.peerID_to_kick = id;
			netGroup.post(message);			
		}
		
		// Send a private message.
		private function pm(peer_id:String):void {
			this.chat.open(peer_id, peers[peer_id].facebook_id, peers[peer_id].username);
		}

		// get a ban reason before performing the ban
		private function ban(id:String):void {

			ban_window = new BanWindow(this);
			ban_window.title = 'Ban ' + peers[id].username;
			ban_window.set_peer_id(id);
			
			PopUpManager.addPopUp(ban_window, this, true);
			
			ban_window.x = uint((this.width / 2) - (ban_window.width / 2));
			ban_window.y = uint((this.height / 4));

		}
		
		// add a record to banned_users indicating a user is banned from a room
		public function createBanRecord(opts:Object):void {
			var variables:URLVariables = new URLVariables;

			variables.wall_id = this.id;
			variables.user_id = peers[opts.peer_id].userID;
			variables.reason = opts.reason;
			variables.action = 'ban';
			
			var request:URLRequest = new URLRequest(CONFIG.SITE_URL + "/ban.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;
			loaders['banRecord'] = new URLLoader;
			loaders['banRecord'].addEventListener(Event.COMPLETE, handleCreateBanRecord);
			//loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			try {
				loaders['banRecord'].load(request);
			} catch (error:IOErrorEvent) {
				Alert.show("There was a problem contacting the server. ", OOPS);
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}			
		}
	
		private function handleCreateBanRecord(event:Event):void{
			try {
				var response:Object = new Object;
				response = JSON.decode(loaders['banRecord'].data);
				
				// do successful stuff
				if(response.success == '1') {
					Alert.show("Successfully banned.", "Good Job");					
				} else {
					// do unsuccessful stuff
					Alert.show(response.friendly_msg, OOPS);
				}
			} catch (e:TypeError) {
				trace("Could not ban user. " + e.getStackTrace());
			}				
		}
		
		// get a flag reason before performing the flag
		private function flag(id:String):void {

			flag_window = new FlagWindow(this);
			flag_window.title = 'Flag ' + peers[id].username;
			flag_window.set_peer_id(id);
			
			PopUpManager.addPopUp(flag_window, this, true);
			
			flag_window.x = uint((this.width / 2) - (flag_window.width / 2));
			flag_window.y = uint((this.height / 4));			
		}

		private function removePeer(peerID:String):void {
			// neighbor was broadcasting 
			if(peers[peerID].camID > -1) {
				var camID:int = peers[peerID].camID;
				camGrid.camWindows[camID].videoStream.close();
				camGrid.camWindows[camID].video.clear();
				this.camGrid.removeCam(camGrid.camWindows[camID]);
				delete camGrid.camWindows[camID];
			}
			delete peers[peerID];
		}	

		public function receiveMessage(message:Object):void{
//			trace('receiving NetGroup.post() message...'+message.type);
			if(message.type == 'username') {
				// set the username	
				if(peers[message.sender] != undefined) {
					peers[message.sender].username = message.username;
					peers[message.sender].location = message.location;
					peers[message.sender].userID = message.userID;
					peers[message.sender].facebook_id = message.facebook_id;
					peers[message.sender].admin_for = message.admin_for;
					peers[message.sender].points = message.points;
					// update any cameras with the name
					if(peers[message.sender].camID > -1) {
						camGrid.camWindows[peers[message.sender].camID].nameLabel.text = message.username;
						camGrid.camWindows[peers[message.sender].camID].pointsLabel.text = message.points;
						camGrid.camWindows[peers[message.sender].camID].locationLabel.text = message.location;
					}
					// update 
					peers[message.sender].userListLabel.text = message.username;
				}				
				this.refreshUserList();
			} else if(message.type == 'public chat' || message.type == 'private chat') {

				// Only process a private message if it is directed to this user.
				if((message.type == 'private chat' && (this.user.fbid == message.target_facebook_id || netConnection.nearID == message.sender_peer_id) )) this.chat.processIncomingMessage(message);
				else if(message.type == 'public chat') this.chat.processIncomingMessage(message);
				
			} else if(message.type == 'kick') {	// user is being kicked from wall
				if(netConnection.nearID.toString() == message.peerID_to_kick) {
					exit('You have been kicked from the room.', OOPS);
				};
			} else if(message.type == 'ban') {	// user is being kicked from wall
				if(netConnection.nearID.toString() == message.peerID_to_ban) {
					exit('You have been banned from the room.', OOPS);
				};
			} else if(message.type == 'flag') {	// user is being kicked from wall
				if(netConnection.nearID.toString() == message.peerID_to_ban) {
					Alert.show("You've been flagged. Behave!", OOPS);
				};
			} else if(message.type == 'make admin') {	// user is being granted admin privelages for the wall
				if(netConnection.nearID == message.peerID_to_adminify) {
					Alert.show("You have been adminified for this room.", "New Permissions", Alert.OK, this);
					adminify();
				} else {
					initializePeer(message.peerID_to_adminify);	// ensure neighbor exists
					peers[message.peerID_to_adminify].admin_for[this.id] = true;
				}
			} else if(message.type == 'revoke admin') {	// user is being granted admin privelages for the wall
				if(netConnection.nearID == message.peerID_to_revoke) {
					Alert.show("Your admin status has been revoked for this wall.", "New Permissions", Alert.OK, this);
					revoke();
				} else {
					initializePeer(message.peerID_to_revoke);	// ensure neighbor exists
					peers[message.peerID_to_revoke].admin_for[this.id] = undefined;
				}

			} else if(message.type == 'game winner') {
				// if this is the first winner, add the 'Winners' header
				if(gameWindow.gameWinnersList.numElements == 0) {
					var gameWinnersListHeader:RichText = new RichText;
					gameWinnersListHeader.textFlow = TextFlowUtil.importFromString("<span fontWeight='bold'>Winners</span>");
					gameWindow.gameWinnersList.addElement(gameWinnersListHeader);
				}
				
				var winnerLabel:Label = new Label;
				winnerLabel.percentWidth = 100;
				winnerLabel.maxDisplayedLines = 1;
				if(netConnection.nearID == message.sender) {
					winnerLabel.text = this.user.username;
					if(myCamIndex > -1) {
						camGrid.camWindows[myCamIndex].animateWinner();
					}
				} else {
					winnerLabel.text = peers[message.sender].username;
					if(peers[message.sender].camID > -1) {
						camGrid.camWindows[peers[message.sender].camID].animateWinner();
					}
				}
				updatePoints(message.sender, Number(message.points_won));
				gameWindow.gameWinnersList.addElement(winnerLabel);
			} 
		}
		
		// current client is a seeder and will share a new banner.
		private function shareNewBanner1():void {
			this.addEventListener(CustomEvent.ROOM_ATTRIBUTES_REFRESHED, shareNewBanner2);
			var opts:Object = {id:this.id};
			this.refreshAttributes(opts);
		}
		
		// new banner_file_id retrieved. download the new banner.
		private function shareNewBanner2(e:Event):void {
			this.removeEventListener(CustomEvent.ROOM_ATTRIBUTES_REFRESHED, shareNewBanner2);
			createTitleBar();
			this.addEventListener(CustomEvent.BANNER_RETRIEVED, shareNewBanner3);
		}
		
		// split up the banner into chunks and share
		private function shareNewBanner3(e:Event):void {
			this.removeEventListener(CustomEvent.BANNER_RETRIEVED, shareNewBanner3);
			sharedObjects[this.banner_shared_object_index].data = this.loaders['getBanner'].data;
			var opts:Object = {file_size: this.loaders['getBanner'].bytesTotal};
			sharedObjects[this.banner_shared_object_index].setMeta(opts);
			sharedObjects[this.banner_shared_object_index].explode();
		}
		
		private function updatePoints(peerID:String, points_won:Number):void {
			if(netConnection.nearID == peerID) {
				this.user.points += Number(points_won);
				if(myCamIndex > -1) {	// is broadcasting; update CamWindow
					camGrid.camWindows[myCamIndex].addPoints(points_won);			
				}

			} else {
				peers[peerID].points += Number(points_won);
				if(peers[peerID].camID > -1) {	// is broadcasting; update CamWindow
					camGrid.camWindows[peers[peerID].camID].addPoints(points_won);			
				}
			}
		}
		
		// sort a temporary Array of users and recreate the list
		private function refreshUserList():void {

			peersArray = new Array;
			for(var k:String in peers) {
				peersArray.push(peers[k]);
			}
			peersArray.sortOn(['username', 'peerID'], [Array.CASEINSENSITIVE, Array.CASEINSENSITIVE]);
			userList.removeAllElements();
			userList.addElement(userListHeader);
			var count:int = 0;	// number of peers with a username
			for(var i:int = 0; i<peersArray.length; i++) {
				if(peersArray[i] != undefined && peersArray[i].userListLabel.text != '') {
					userList.addElement(peersArray[i].userListLabel);
					count++;
				}
			}
			if(count == 1) {
				userListHeader.text = "you're the only one here";
			} else {
				userListHeader.text = count + ' ppl here';
			}
		}
		
		// Check for available video cell. 
		// limit:Boolean decides whether to return -1 if MAX_CAMERAS is exceeded
		private function getNextAvailableCell(limit:Boolean = true):int {
			var num_cameras_limit:uint;
			if(limit) num_cameras_limit = camGrid.MAX_CAMERAS;
			else num_cameras_limit = 1000;
			for(var i:int=0; i < num_cameras_limit; i++) {
				if(camGrid.camWindows[i] == undefined) return i;
			}
			return -1;
		}
		
		// check camera streams
		private function checkForTalk():void {
			for(var i:int=0; i<camGrid.MAX_CAMERAS+10; i++) {
				if(camGrid.camWindows[i] == undefined || camGrid.camWindows[i] == null || !netConnection.connected) {
					continue;
				}
				if(camGrid.camWindows[i].videoStream.info.audioBytesPerSecond) {
					camGrid.camWindows[i].talkingLabel.visible = true;
				} else {
					camGrid.camWindows[i].talkingLabel.visible = false;
				}
			}
		}
		
		private function micActivity(e:ActivityEvent):void {
			trace('mic activity:'+mic.activityLevel);
		}

		private function addCamera(event:MouseEvent):Boolean {
			if(netConnection.connected == false) {
				Alert.show("Must be connected to the room first. Try again in a few seconds.", OOPS);
				return false;
			}
			if(myCamIndex != -1) {
				Alert.show("You are already broadcasting your webcam. If it isn't showing, right click anywhere then click Settings and make sure Allow is chosen for the camera.", OOPS);
				return false;
			}
			var i:int = 0;	// counter
			myCamIndex = getNextAvailableCell();
			if(myCamIndex == -1) {
				Alert.show("Too many cameras on the screen. This can happen even if there appears to be open spots. Try again soon!", OOPS);
				return false; // failed - no video cells available
			}
			camGrid.camWindows[myCamIndex] = new CamWindow(VIDEO_CELL_W, VIDEO_CELL_H); // 11/17/2010

			if(Camera.getCamera() == null) {
				Alert.show("We could not find your camera. Check under the sofa?", OOPS);
				delete camGrid.camWindows[myCamIndex];
				myCamIndex = -1;
				return false;
			} else {				
				var cam:Camera = Camera.getCamera();
			}
			mic = Microphone.getMicrophone();
			cam.setQuality(0, 80); 
			cam.setMode(camGrid.camWindows[myCamIndex].video.width, camGrid.camWindows[myCamIndex].video.height, 20);
			cam.setLoopback(true);
			cam.setMotionLevel(5,3000000);  
			cam.addEventListener(ActivityEvent.ACTIVITY, camera_activity);	
			camGrid.camWindows[myCamIndex].videoStream = new NetStream(netConnection,groupspec.groupspecWithAuthorizations());
			camGrid.camWindows[myCamIndex].videoStream.bufferTime = 0;
			camGrid.camWindows[myCamIndex].videoStream.attachCamera(cam);
			camGrid.camWindows[myCamIndex].videoStream.publish(netConnection.nearID);
			camGrid.camWindows[myCamIndex].video.attachCamera(cam);
			camGrid.camWindows[myCamIndex].video;
			camGrid.camWindows[myCamIndex].z = 0;

			if(peers[netConnection.nearID] == undefined) initializePeer(netConnection.nearID);
			camGrid.camWindows[myCamIndex].user = peers[netConnection.nearID];
			camGrid.camWindows[myCamIndex].nameLabel.text = user['username'] ? user['username'] : 'undef';
			camGrid.camWindows[myCamIndex].pointsLabel.text = user['points'];
			camGrid.camWindows[myCamIndex].locationLabel.text = user['location'];
			camGrid.camWindows[myCamIndex].addEventListener(MouseEvent.CLICK, handleCamWindowClick);	// 11/17/2010
			camGrid.addCam(camGrid.camWindows[myCamIndex]);
			return true;
		}
		
		private function camera_activity(evt:ActivityEvent):void {  
			if(evt.type =="activity" && evt.activating==false && myCamIndex > -1) {  
				camGrid.camWindows[myCamIndex].videoStream.close();
				camGrid.camWindows[myCamIndex].video.clear();
				myCamIndex = -1;
			}  
		}	
		
		private function showAdminScreenHandler(e:MouseEvent):void {
			showAdminScreen();
		}

		public function showAdminScreen():void {
			popupCanvas = new PopupCanvas(this);
			PopUpManager.addPopUp(popupCanvas, this, true);
			adminScreen = new WallAdminScreen(this);
			adminScreen.adminScreenSubmit.addEventListener(MouseEvent.CLICK, saveWall);
			this.popupCanvas.add(adminScreen);
		}
		
		// save wall settings. only admins can do this
		private function saveWall(e:MouseEvent):void {
			this.loaders['save_wall'] = new MultipartURLLoader;
			this.loaders['save_wall'].addVariable('id', this.id);
			
			if(adminScreen.passwordInput.text == '') {	// password is being removed 
				this.loaders['save_wall'].addVariable('password', '');
			} else if(adminScreen.passwordInput.text != CONFIG.WALL_PASS_NO_CHANGE) {	// new password
				this.loaders['save_wall'].addVariable('password', HMAC.hash(CONFIG.HASH_KEY,adminScreen.passwordInput.text, MD5));
			} else {	// has password, not changing
				this.loaders['save_wall'].addVariable('password', CONFIG.WALL_PASS_NO_CHANGE);
			}

			// new banner
			if(adminScreen.bannerAction == 'new') {
				this.loaders['save_wall'].addFile(adminScreen.bannerFileReference.data, adminScreen.bannerFileReference.name, 'banner');
				this.loaders['save_wall'].addVariable('banner_action', 'new');
			} else if(adminScreen.bannerAction == 'clear') {
				this.loaders['save_wall'].addVariable('banner_action', 'clear');
			}
			
			this.loaders['save_wall'].addVariable('game_on', (adminScreen.gameOnCheckbox.selected ? 1 : 0));
			this.loaders['save_wall'].addVariable('include_in_search', (adminScreen.include_in_search_checkbox.selected ? 1 : 0));
			this.loaders['save_wall'].addVariable('city_id', (adminScreen.city_directory_dropdown.selectedIndex != -1 ? adminScreen.city_directory_dropdown.selectedItem.id : 0));
			this.loaders['save_wall'].addEventListener(Event.COMPLETE, saveWallHandler);
			//loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);

			try {
				this.loaders['save_wall'].load(CONFIG.SITE_URL + "/save_wall.php");
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}
		}
		
		// update the database with new room info
		private function saveWallHandler(event:Event):void{
			try {
				var response:Object = new Object;
				response = JSON.decode(this.loaders['save_wall'].loader.data);
				
				// do successful stuff
				if(response.success == '1') {

					// is the game being turned on or off?
					for(var k:String in response.objects) {
						processNewObject(Number(k), response.objects[k]);	// do something with the new object
					}

					PopUpManager.removePopUp(popupCanvas);
					
					// if the banner was updated and the user is a seeder, this 
					// condition prevents refreshAttributes from running twice
					if(adminScreen.bannerAction != 'new' || this.isSeeder() == 0) {
						var opts:Object = {id:this.id};					
						this.refreshAttributes(opts);
					}
					
					adminScreen.giveBannerBack();
					
					// If the banner is new, instantly update the current banner.
					// Everyone else will wait for the P2P propogation.
					if(adminScreen.bannerAction == 'new' && this.isSeeder() == false ) {
						createTitleBanner(adminScreen.uploaded_banner_loader.content);
					} else if(adminScreen.bannerAction == 'clear') {
						this.banner_file_id = 0;
						this.createTitleBar();	
					}

				} else {
					// do unsuccessful stuff

				}
			} catch (e:TypeError) {
				trace("Could not save wall attributes. " + e.getStackTrace());
			}				
		}
		
		// enables admin functions for current user
		private function adminify():void {
			this.user.admin_for[this.id] = true;
			showAdminButton();	// show wall admin button in menu
			for(var i:int=0; i<camGrid.MAX_CAMERAS+10; i++) {
				if(camGrid.camWindows[i] != undefined) {
					camGrid.camWindows[i].kickButton.visible = true;
					camGrid.camWindows[i].banButton.visible = true;
				}
			}			
		}

		// disables admin functions for current user
		private function revoke():void {
			this.user.admin_for[this.id] = undefined;
			hideAdminButton();	// hide wall admin button
			for(var i:int=0; i<camGrid.MAX_CAMERAS; i++) {
				camGrid.camWindows[i].kickButton.visible = false;
				camGrid.camWindows[i].banButton.visible = false;
			}			
		}
		
		private function clearAdminStuff():void {
			for(var i:int=0; i<camGrid.MAX_CAMERAS+10; i++) {
				if(camGrid.camWindows[i] != undefined) {
					camGrid.camWindows[i].kickButton.visible = false;
					camGrid.camWindows[i].banButton.visible = false;
				}
			}						
		}

	}
}