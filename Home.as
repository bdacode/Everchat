package
{
	import com.adobe.crypto.HMAC;
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;
	
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.TextEvent;
	import flash.geom.Matrix;
	import flash.media.Sound;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	import flash.net.navigateToURL;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import mx.collections.ArrayCollection;
	import mx.containers.Form;
	import mx.containers.FormHeading;
	import mx.containers.FormItem;
	import mx.controls.Alert;
	import mx.controls.Image;
	import mx.controls.Text;
	import mx.core.FTETextField;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.graphics.GradientEntry;
	import mx.graphics.LinearGradient;
	import mx.graphics.RadialGradient;
	import mx.graphics.SolidColor;
	import mx.managers.PopUpManager;
	
	import spark.components.Button;
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.Label;
	import spark.components.List;
	import spark.components.RichText;
	import spark.components.Scroller;
	import spark.components.TextInput;
	import spark.components.VGroup;
	import spark.layouts.VerticalLayout;
	import spark.layouts.supportClasses.LayoutBase;
	import spark.primitives.BitmapImage;
	import spark.primitives.Rect;
	import spark.utils.TextFlowUtil;
	
	public class Home extends Group
	{
		// parent 
		private var master:everchat;	
		private var user:User;

		// layers & layout
		private var mainLayer:Group = new Group;
		private var mainContent:VGroup = new VGroup;	// holds most content
		private var background:Group = new Group;
		private var backgroundRect:Rect = new Rect;
		
		// ui
		[Embed(source="everchat_white_m.png")]
		private var title:Class;
		private var joinWallField:TextInput = new TextInput;
		private var joinWallSubmit:Button = new Button;
		private var scroller:Scroller = new Scroller;
		public var popupCanvas:PopupCanvas;
		private var favewalls:VGroup = new VGroup;
		public var favewallsLabel:Label = new Label;
		public var favewallsList:VGroup = new VGroup;
		public var favewallsListScroller:Scroller = new Scroller;
		private var userName:Label = new Label;
		private var col1:VGroup = new VGroup;	// layout
		private var userPanel:VGroup = new VGroup;	// layout
		
		// forms
		private var signupFormContainer:Group = new Group;
		private var signupUsernameInput:TextInput = new TextInput;
		private var signupPasswordInput:TextInput = new TextInput;		
		private var signupEmailInput:TextInput = new TextInput;			
		private var loginFormContainer:Group = new Group;
		private var loginEmailInput:TextInput = new TextInput;
		private var loginPasswordInput:TextInput = new TextInput;		
		private var newWallFormContainer:HGroup = new HGroup;
		private var newWallField:TextInput = new TextInput;
		private var newWallSubmit:Button = new Button;		
		private var joinWallContainer:HGroup = new HGroup;
		private var playButton:Button = new Button;
		private var contact_form:ContactWindow;
		
		// members
		public var CONFIG:Object;

		// utils
		private var loaders:Object = new Object;	// load external files
		private var anything:Object = Object;		// store stuff that will probably be moved and need not be a member
		
		public function Home(master:everchat)
		{
			super();
			this.master = master;
			this.CONFIG = this.master.CONFIG;	// set the universal config
			this.mainLayer.percentWidth = 100;
			this.height = this.mainLayer.height = this.master.height;
			this.mainContent.percentWidth = 100;
			this.mainContent.horizontalAlign = 'center';
			this.user = master.user;
			this.user.addEventListener(Event.CHANGE, updateUser);
			this.addElement(mainLayer);
			addAmbientBackground();
			this.mainLayer.addElement(this.mainContent);			
			
			newWallFormContainer.gap = joinWallContainer.gap = 10;
			
			var row1:HGroup = new HGroup;	// Home content organized into columns
			row1.gap = 20;
			row1.paddingTop = 20;
			
			// vertical group
			col1.left = 0;
			col1.y = 160;
			col1.gap = 20;
			
			// logo 
			var image:Image = new Image;
			image.source = title;
			col1.addElement(image);
			
			// play game button
			playButton.label = 'Play';
			playButton.x = 200;
			playButton.y = 350;
			playButton.height = 60;
			playButton.width = 380;
			playButton.addEventListener(MouseEvent.CLICK, findGame);
			col1.addElement(playButton);	
						
			// join room name field
			joinWallField.setStyle("fontSize", 25);
			joinWallField.setStyle("focusSkin", null);
			joinWallField.setStyle("paddingLeft", 8);
			joinWallField.setStyle("paddingRight", 8);
			joinWallField.setStyle("focusedTextSelectionColor", 0xfaed00);
			joinWallField.width = 250;
			joinWallField.height = 60;				
			joinWallField.addEventListener(FlexEvent.ENTER, joinWallFromTextInput);
			joinWallContainer.addElement(joinWallField);
			
			// join room submit button
			joinWallSubmit.label = 'Join Room';
			joinWallSubmit.toolTip = 'Enter an existing room using its name'; 
			joinWallSubmit.focusEnabled = false;
			joinWallSubmit.height = 60;
			joinWallSubmit.width = 120;
			joinWallSubmit.addEventListener(MouseEvent.CLICK, joinWallFromTextInput);
			joinWallContainer.addElement(joinWallSubmit);
			col1.addElement(joinWallContainer);
			
			// new room name field
			newWallField.setStyle("fontSize", 25);
			newWallField.setStyle("focusSkin", null);
			newWallField.setStyle("paddingLeft", 8);
			newWallField.setStyle("paddingRight", 8);
			newWallField.setStyle("focusedTextSelectionColor", 0xfaed00);			
			newWallField.width = 250;
			newWallField.height = 60;				
			newWallField.addEventListener(FlexEvent.ENTER, createNewWall);
			this.newWallFormContainer.addElement(newWallField);
			
			// new room submit button
			newWallSubmit.label = 'Create Room';
			newWallSubmit.toolTip = 'You will be the administrator. You can adminify other people, set a room password, and toggle games off or on'; 
			newWallSubmit.focusEnabled = false;
			newWallSubmit.height = 60;
			newWallSubmit.width = 120;
			newWallSubmit.addEventListener(MouseEvent.CLICK, createNewWall);
			this.newWallFormContainer.addElement(newWallSubmit);	
			col1.addElement(this.newWallFormContainer);

			// add first column to row
			row1.addElement(col1);

			var col2:VGroup = new VGroup;
			col2.right = 0;
			col2.y = 20;
			col2.width = 300;
			col2.horizontalAlign = 'center';
			col2.gap = 20;
			
			// create userPanel_container where userPanel_background and userPanel can be added
			var userPanel_container:Group = new Group;
			userPanel_container.percentWidth = userPanel.percentWidth = 100;
			
			var userPanel_background:Rect = new Rect;
			userPanel_background.radiusX = userPanel_background.radiusY = 15;
			userPanel_background.percentHeight = userPanel_background.percentWidth = 100;
			var userPanel_background_fill:SolidColor = new SolidColor(0xFFFFFF, 0.7);
			userPanel_background.fill = 	userPanel_background_fill;

			userPanel_container.addElement(userPanel_background);
			userPanel_container.addElement(userPanel);
			
			// store items in a horizontal group
			userPanel.gap = 20;
			userPanel.paddingBottom = userPanel.paddingTop = userPanel.paddingLeft = userPanel.paddingRight = 20;
			
			var userAccountGroup:VGroup = new VGroup;
			userAccountGroup.percentWidth = 100;
			userName.text = this.user.username;
			userName.setStyle('fontSize',18);
			userName.percentWidth = 100;
			userAccountGroup.addElement(userName);

			// user buttons
			var userButtons:HGroup = new HGroup;
			userButtons.percentWidth = 100;
			var accountButton:Button = new Button; 			// edit account button
			accountButton.label = 'Account';
			accountButton.addEventListener(MouseEvent.CLICK, showAccountEdit);
			userButtons.addElement(accountButton);
			userButtons.addElement(this.master.logoutButton);
			userAccountGroup.addElement(userButtons);
			userPanel.addElement(userAccountGroup);
			col2.addElement(userPanel_container);
			
			// favorite rooms
			favewalls.percentWidth = 100;
			
			this.userPanel.addElement(favewalls);
			
			// some buttons
			var linkButtons:VGroup = new VGroup;
			linkButtons.percentWidth = 100;
			
			// Show contact form button.
			var contact_button:Button = new Button;
			contact_button.label = 'Leave a message';
			contact_button.percentWidth = 100;
			contact_button.addEventListener(MouseEvent.CLICK, contactHandler);
			linkButtons.addElement(contact_button);
			
			// submit trivia question
			var submitTriviaButton:Button = new Button;
			submitTriviaButton.label = 'Submit trivia question';
			submitTriviaButton.percentWidth = 100;
			submitTriviaButton.addEventListener(MouseEvent.CLICK, submitTriviaButtonHandler);
			linkButtons.addElement(submitTriviaButton);
			
			// leaderboard
			var leaderboardButton:Button = new Button;
			leaderboardButton.label = 'Leaderboard';
			leaderboardButton.percentWidth = 100;
			leaderboardButton.addEventListener(MouseEvent.CLICK, showLeaderboard);
			linkButtons.addElement(leaderboardButton);

			// Add all the buttons.
			col2.addElement(linkButtons);
			
			if((this.master.backgrounds[this.master.background_index] as BackgroundImage).hasCreditDisplay()) {
				col2.addElement((this.master.backgrounds[this.master.background_index] as BackgroundImage).getCreditGroup());
			}
			
			buildFavoritesList();

			// add second column to row
			row1.addElement(col2);
			
			var col3:VGroup = new VGroup;
			col3.width = 300;
			col3.horizontalAlign = 'center';
			col3.gap = 20;

			var browser:Browser = new Browser(this.CONFIG);
			browser.addEventListener(CustomEvent.JOIN_ROOM, joinRoomByID);
			col3.addElement(browser);
			
			row1.addElement(col3);

			// add the content
			row1.addEventListener(Event.ADDED, resizeHandler);
			this.mainContent.addElement(row1);
						
			this.resize();			
		}
		
		public function resizeHandler(e:Event):void {
			this.resize();
		}
		
		public function resize():void {
			if(popupCanvas != null) {
				this.popupCanvas.height = this.popupCanvas.canvas.height = this.master.height;
				this.popupCanvas.width = this.popupCanvas.canvas.width = this.master.width;	
			}
			if(this.user.popupCanvas != null) {
				this.user.popupCanvas.height = this.user.popupCanvas.canvas.height = this.master.height;
				this.user.popupCanvas.width = this.user.popupCanvas.canvas.width = this.master.width;
			}
			this.width = this.mainLayer.width = this.master.width;
			this.height = this.mainLayer.height = this.master.height;
			this.mainContent.x = (this.width / 2) - (this.mainContent.width / 2);
		}
		
		public function addAmbientBackground():void {
			background.percentHeight = background.percentWidth = backgroundRect.percentHeight = backgroundRect.percentWidth = 100;
			var backgroundGradient:LinearGradient = new LinearGradient;
			backgroundGradient.entries = [new GradientEntry(0x767676), new GradientEntry(0xEEEEEE)];
			backgroundGradient.rotation = 270;
			backgroundRect.fill = backgroundGradient;
			background.addElement(backgroundRect);
			background.depth = -2;
			this.addElement(background);
		}
		
		// show leaderboard
		private function showLeaderboard(e:MouseEvent):void {
			popupCanvas = new PopupCanvas(this);
			PopUpManager.addPopUp(popupCanvas, this, true);
			var l:Leaderboard = new Leaderboard(this);
			popupCanvas.add(l);
		}
		
		// show the account edit screen
		private function showAccountEdit(MouseEvent:Event):void {
			this.user.account(this);
		}
		
		private function joinRoomByID(e:CustomEvent):void {
			this.master.removeElement(this);
			var enter_opts:Object = new Object;
			enter_opts.id = e.data.room_id;
			this.master.enterWall(enter_opts);
		}
				
		private function joinWallFromTextInput(e:Event):void {
			this.master.removeElement(this);
			joinWallByName(joinWallField.text);
		}
		
		private function joinWallFromLabel(e:Event):void {
			this.master.removeElement(this);
			joinWallByName(e.currentTarget.text);
		}
		
		private function joinWallByName(n:String):void {
			var opts:Object = new Object;
			opts.name = n;
			this.master.enterWall(opts);
		}
									
		public function refresh():void {
			buildFavoritesList();
			userName.text = this.user.username;
		}
		
		public function buildFavoritesList():void {
			this.favewalls.removeAllElements();
			favewallsList.removeAllElements();

			favewallsList = new VGroup;
			favewallsList.id = 'favewallsList';
			favewallsList.percentWidth = 100;
			favewallsListScroller.viewport = favewallsList;
			favewallsListScroller.percentWidth = 100;
			favewallsListScroller.maxHeight = 125;
			
			favewallsLabel.text = 'Favorites';
			favewallsLabel.x = 500;
			favewallsLabel.y = 50;
			favewalls.addElement(favewallsLabel);
			
			var count:int = 0;
			for(var k:String in this.user.favewalls) {
				
				var favewall_link:Label = new Label;
				favewall_link.percentWidth = 100;
				favewall_link.width = 180;
				favewall_link.maxDisplayedLines = 1;
				favewall_link.text = this.user.favewalls[k].name;
				favewall_link.setStyle('color', 0x0000FF);
				favewall_link.setStyle('textDecoration', 'underline');
				favewall_link.buttonMode = true;
				favewall_link.addEventListener(MouseEvent.CLICK, joinWallFromLabel);
				
				var favewall_member_count:Label = new Label;
				favewall_member_count.text = String(int(this.user.favewalls[k].num_members)-1);
				
				var favewall_row:HGroup = new HGroup;
				favewall_row.addElement(favewall_link);
				favewall_row.addElement(favewall_member_count);
				
				favewallsList.addElement(favewall_row);
				count++;
				
			}
			if(count == 0) {
				var noneMsg:Label = new Label;
				noneMsg.text = 'Add a favorite by joining a room and then clicking the +Favorite button.';
				noneMsg.percentWidth = 100;
				favewalls.addElement(noneMsg);
			} else {
				favewalls.addElement(favewallsListScroller);
			}
		}
				
		private function createNewWall(e:Event):void {
			var variables:URLVariables = new URLVariables;
			variables.name = newWallField.text;
			var request:URLRequest = new URLRequest(CONFIG.SITE_URL + "/create_wall.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;
			loaders['create_wall'] = new URLLoader;
			loaders['create_wall'].addEventListener(Event.COMPLETE, handleCreateWall);
			//loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			try {
				loaders['create_wall'].load(request);
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}					
		}
		
		private function handleCreateWall(e:Event):void{
			try {
				var response:Object = new Object;
				response = JSON.decode(loaders['create_wall'].data);
				if(response.success == '1') {
					// do successful stuff
					this.master.removeElement(this);
					var wall_opts:Object = new Object;
					wall_opts.id = response.new_wall_id;
					this.user.admin_for[response.new_wall_id] = true;
					wall_opts.state = 1;	// show admin screen immediately
					this.master.enterWall(wall_opts);
				} else {
					// do unsuccessful stuff
					Alert.show(response.msg, 'Oops!');
				}
			} catch (e:TypeError) {
				trace("Could not create wall.");
			}				
		}
		
		private function findGame(e:Event):void {
			var variables:URLVariables = new URLVariables;
			var request:URLRequest = new URLRequest(CONFIG.SITE_URL + "/find_game.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;
			loaders['find_game'] = new URLLoader;
			loaders['find_game'].addEventListener(Event.COMPLETE, handleFindGame);
			//loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			try {
				loaders['find_game'].load(request);
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}	
		}
		
		private function handleFindGame(e:Event):void {
			try {
				var response:Object = new Object;
				response = JSON.decode(loaders['find_game'].data);
				if(response.success == '1') {
					// do successful stuff
					this.master.removeElement(this);
					var wall_opts:Object = new Object;
					wall_opts.id = response.wall_id;
					this.master.enterWall(wall_opts);
				} else {
					// do unsuccessful stuff
					Alert.show(response.msg, 'Oops!');
				}
			} catch (e:TypeError) {
				trace("Could not create wall.");
			}	
		}
		
		// called when this.user is updated
		private function updateUser(e:Event):void {
			userName.text = this.user.username;
		}
		
		// Show the contact form.
		private function contactHandler(e:MouseEvent):void {

			contact_form = new ContactWindow(this, this.CONFIG, 'Leave a message after the beep');
			contact_form.set_user(this.user);

			PopUpManager.addPopUp(contact_form, this, true);
			
			contact_form.x = uint((this.width / 2) - (contact_form.width / 2));
			contact_form.y = uint((this.height / 4));	
			
			// Play the answering machine beep :)
			var sound_req:URLRequest = new URLRequest(this.CONFIG.SITE_URL + "/files/audio/answering_machine.mp3");
			
			var answering_machine:Sound = new Sound();
			answering_machine.load(sound_req);
			
			answering_machine.addEventListener(Event.COMPLETE, playAnsweringMachine);
		}
		
		private function playAnsweringMachine(e:Event):void {
			e.target.play();
		}
		
		// open new window to the trivia submit form
		private function submitTriviaButtonHandler(e:MouseEvent):void {
			contact_form = new ContactWindow(this, this.CONFIG, "Thanks for doing our job");
			contact_form.set_user(this.user);
			contact_form.set_instructions("We'll take what you submit and run with it. Thanks!");
				
			PopUpManager.addPopUp(contact_form, this, true);
			
			contact_form.x = uint((this.width / 2) - (contact_form.width / 2));
			contact_form.y = uint((this.height / 4));	
		}
	}
}