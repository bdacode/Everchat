package
{
	import com.adobe.crypto.HMAC;
	import com.adobe.crypto.MD5;
	import com.adobe.serialization.json.JSON;
	import com.adobe.serialization.json.JSONParseError;
	
	import flash.display.DisplayObject;
	import flash.errors.IOError;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import mx.controls.Alert;
	import mx.events.FlexEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.Button;
	import spark.components.HGroup;
	import spark.components.Label;
	import spark.components.TextInput;
	import spark.components.VGroup;

	[Event(name="change",type="flash.events.Event")]
	public class User extends EventDispatcher {

		// user
		public var userID:int = 0;					// unique identifier users.id in database
		public var name:String = '';				// FB: real name of person
		public var first_name:String = '';			// FB: first name of person
		public var birthday:String = '';			// FB: birthday
		public var email:String = '';				// FB: user's email 
		public var location:String = '';			// FB: user's location 
		public var fbid:Number = 0;					// FB: facebook ID
		public var points:Number = 0;				// user's total points
		public var username:String = new String;	// name used for chats
		public var admin_for:Object = new Object;	// key=>boolean where key is wall_id 
		public var favewalls:Object = new Object;	// key=>boolean where key is wall_id 
		public var is_logged_in:Boolean = false;	// status
		public var response:Object = new Object;	// store callback-oriented data
		public var is_game_seeder:Boolean = false;	// is the user going to NetGroup.post() games to the group?
		public var num_logins:int;					// number of timers the user has logged in
		
		// ui
		public var popupCanvas:PopupCanvas;
		private var parentContainer:DisplayObject;
		
		// utils
		private var loaders:Object = new Object;
		
		// settings
		private var CONFIG:Object;
		
		// forms
		private var usernameInput:TextInput;
		private var submitUsernameButton:Button;
		private var cancelButton:Button;

		public function User(opts:Object=null) {
			super();
			if(opts != null) {
				if(opts.CONFIG != undefined) {
					this.CONFIG = opts.CONFIG;
				}
			}
		}
		
		// set the data retrieved from facebook
		public function setFacebookData(data:Object):void {
			if(data.id != undefined) this.fbid = Number(data.id);
			if(data.name != undefined) this.name = data.name;
			if(data.first_name != undefined) this.first_name = data.first_name;
			if(data.birthday != undefined) this.birthday = data.birthday;
			if(data.location != undefined && data.location.name != undefined) this.location = data.location.name;
			if(data.email != undefined) this.email = data.email;
		}

		// attempt to retrieve user data
		public function login(passedHandler:Function):void {
			var variables:URLVariables = new URLVariables;
			variables.fbid = this.fbid;
			variables.location = this.location;
			variables.first_name = this.first_name;
			variables.email = this.email;
			var request:URLRequest = new URLRequest(CONFIG.SITE_URL + "/login.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;
			loaders['login'] = new URLLoader;
			loaders['login'].addEventListener(Event.COMPLETE, passedHandler);
			loaders['login'].addEventListener(IOErrorEvent.IO_ERROR, loginHandler);
			
			try {
				loaders['login'].load(request);
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			} catch (error:IOError) {
				trace("IO error occured during loaders[login].load()");
			}
		}
		
		// handle login events (other than Event.COMPLETE which is handled by a passed function)
		private function loginHandler(e:Event):void {
			if(e.type == IOErrorEvent.IO_ERROR) {
				Alert.show("We're out to lunch - please try again soon.", "Oops!");
			}
		}

		// use retrieved data for attribute assignment
		public function finishLogin():Boolean {
			
			try {
				response = JSON.decode(loaders['login'].data);				
			} catch (err:JSONParseError) {
				Alert.show("Something went wrong. We're working on it.", "Oops!");
				trace(err.getStackTrace());
			}
			
			if(response.success == '1') {
				// do successful stuff
				this.username = response.username;
				this.points = Number(response.points);
				this.is_logged_in = true;
				this.userID = response.userID;
				this.admin_for = response.admin_for;
				this.favewalls = response.favewalls;
				this.num_logins = int(response.num_logins);
				return true;
			} else {
				// do unsuccessful stuff
				return false;
			}
		}
		
		// attempt to save user data
		public function save(opts:Object, url_loader:URLLoader, handler:Function):void {
			var variables:URLVariables = new URLVariables;
			for(var k:String in opts) {
				variables[k] = opts[k];
			}
			var request:URLRequest = new URLRequest(CONFIG.SITE_URL + "/save_user.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;
			url_loader.addEventListener(Event.COMPLETE, handler);
			
			try {
				url_loader.load(request);
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}
		}
		
		// show user account modification screen
		public function account(parentContainer:DisplayObject):void {
			popupCanvas = new PopupCanvas(parentContainer);
			PopUpManager.addPopUp(popupCanvas, parentContainer, true);
			
			var FIELD_WIDTH:int = 250;
			var FIELD_FONT_SIZE:int = 25;
			
			var container:VGroup = new VGroup;
			container.horizontalAlign = 'center';
			container.paddingBottom = container.paddingTop = container.paddingRight = container.paddingLeft = 20;
			container.width = 600;
			container.gap = 20;
			
			// title message
			var titleLabel:Label = new Label;
			titleLabel.text = 'Your Account';
			titleLabel.setStyle('fontSize', 30);
			titleLabel.setStyle('fontWeight', 'bold');
			titleLabel.setStyle('fontFamily', 'Arial');
			titleLabel.setStyle('color', 0xFFFFFF);
			container.addElement(titleLabel);

			// the form
			var form:VGroup = new VGroup;
			form.horizontalAlign = 'center';
			form.percentWidth = 100;
			
			// username
			var usernameVertical:VGroup = new VGroup;
			usernameVertical.horizontalAlign = 'center';
			usernameVertical.gap = 10;
			usernameVertical.paddingBottom = 10;
			
			var usernameLabel:Label = new Label;
			usernameLabel.text = 'Enter a name you want to go by:';
			usernameLabel.setStyle('fontSize',FIELD_FONT_SIZE);
			usernameLabel.setStyle('fontFamily', 'Arial');
			usernameLabel.setStyle('color', 0xFFFFFF);
			usernameLabel.percentWidth = 100;
			usernameLabel.setStyle('textAlign', 'center');
			usernameVertical.addElement(usernameLabel);	
			
			usernameInput = new TextInput;
			usernameInput.setStyle("fontSize", FIELD_FONT_SIZE);
			usernameInput.width = FIELD_WIDTH;
			usernameInput.setStyle('paddingTop', 10);
			usernameInput.setStyle('paddingBottom', 10);
			usernameInput.setStyle('paddingRight', 10);
			usernameInput.setStyle('paddingLeft', 10);
			usernameInput.text = this.username;
			usernameInput.setStyle('textAlign', 'center');
			usernameInput.addEventListener(FlexEvent.ENTER, saveAccount);
			usernameVertical.addElement(usernameInput);
			form.addElement(usernameVertical);
			
			var buttons:HGroup = new HGroup;
			buttons.gap = 10;
			buttons.paddingTop = 10;
			
			submitUsernameButton = new Button;
			submitUsernameButton.label = 'Save';
			submitUsernameButton.height = 60;
			submitUsernameButton.width = 120;
			submitUsernameButton.addEventListener(MouseEvent.CLICK, saveAccount);
			buttons.addElement(submitUsernameButton);
			
			cancelButton = new Button;
			cancelButton.label = 'Cancel';
			cancelButton.height = 60;
			cancelButton.width = 120;
			cancelButton.addEventListener(MouseEvent.CLICK, cancel);
			buttons.addElement(cancelButton);
			
			form.addElement(buttons);
			container.addElement(form);
			
			// add form to popup window
			popupCanvas.add(container);
		}
		
		private function cancel(e:MouseEvent):void {
			PopUpManager.removePopUp(popupCanvas);
		}
		
		public function saveAccount(e:Event):void {
			var opts:Object = new Object;
			if(usernameInput.text != this.username) opts.username = usernameInput.text;
			opts.user_id = this.userID;
			loaders['saveAccount'] = new URLLoader;
			this.save(opts, loaders['saveAccount'], handleSaveAccount);
		}
		
		// close the account edit window
		public function handleSaveAccount(e:Event):void {
			try {
				var response:Object = new Object;
				response = JSON.decode(loaders['saveAccount'].data);
				if(response.success == '1') {
					
					// do successful stuff
					if(response.username) this.username = response.username;
					PopUpManager.removePopUp(popupCanvas);
					
					dispatchEvent(new Event(Event.CHANGE));			
					
				} else {
					// do unsuccessful stuff
					Alert.show("Problem saving the account info. " + response.msg, "Oops!");					
				}
			} catch (e:TypeError) {
				trace("Could not save account information.");
			}			
		}
	}
}