package
{
	import com.adobe.serialization.json.JSON;
	import com.facebook.graph.Facebook;
	
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.Loader;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.utils.setTimeout;
	
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.Image;
	import mx.controls.Label;
	import mx.core.UIComponent;
	import mx.events.FlexEvent;
	import mx.graphics.GradientEntry;
	import mx.graphics.LinearGradient;
	import mx.managers.PopUpManager;
	
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.RichText;
	import spark.components.TextInput;
	import spark.components.VGroup;
	import spark.effects.Rotate3D;
	import spark.primitives.Rect;
	import spark.utils.TextFlowUtil;
	
	public class Login extends Group
	{
		
		// parent 
		private var master:everchat;	
		
		// layers, layout
		private var mainLayer:Group = new Group;
		public var popupCanvas:PopupCanvas;				// for messages and forms that take up entire screen
		private var mainContent:VGroup = new VGroup;;	// simple box holding content
		private var background:Group = new Group;
		private var backgroundRect:Rect = new Rect;

		// members
		public var CONFIG:Object;
		private var user:User;
		private var loaders:Object = new Object;		// key-named loader objects 
//		private var loader:URLLoader = new URLLoader;
		
		// ui, images
		[Embed(source="everchat_l.png")]
		private var title:Class;
		private var titleImage:Bitmap;
		private var titleImageContainer:UIComponent = new UIComponent;

		// forms
		public var usernameInput:TextInput = new TextInput;
		public var submitUsernameButton:Button = new Button;
		public var loginButton:Button = new Button;


		public function Login(master:everchat)
		{
			super();
			this.master = master;
			this.CONFIG = this.master.CONFIG;	// set the universal config
			this.width = this.mainLayer.width = this.master.width;
			this.height = this.mainLayer.height = this.master.height;
			this.user = master.user;
			this.mainContent.width = 650;
			this.mainContent.horizontalAlign = 'center';
			this.mainContent.gap = 20;
			addBackground();
			this.mainLayer.addElement(mainContent);
			this.addElement(mainLayer);
			showTitleImage();
			Facebook.init("164947616866256", handleFBLogin);
			showLoginStuff();
			this.resize();
		}
		
		public function resize():void {
			this.width = this.mainLayer.width = this.master.width;
			this.height = this.mainLayer.height = this.master.height;
			this.mainContent.x = (this.width / 2) - (this.mainContent.width / 2);
		}
		
		private function spinLogo():void {
			var r:Rotate3D = new Rotate3D;
			r.target = this.titleImageContainer;
			r.angleXFrom = 0;
			r.angleXTo = 360;
			r.autoCenterTransform = true;
			r.disableLayout = true;
			r.repeatCount = 1;
			r.duration = 1000;
			r.play();
		}
		
		public function addBackground():void {
			background.percentHeight = background.percentWidth = backgroundRect.percentHeight = backgroundRect.percentWidth = 100;
			var backgroundGradient:LinearGradient = new LinearGradient;
			backgroundGradient.entries = [new GradientEntry(0x767676), new GradientEntry(0xEEEEEE)];
			backgroundGradient.rotation = 270;
			backgroundRect.fill = backgroundGradient;
			background.addElement(backgroundRect);
			this.mainLayer.addElement(background);
		}
		
		public function showTitleImage():void {
			this.mainContent.addElement(titleImageContainer);
			titleImage = new title();
			titleImageContainer.height = titleImage.height;
			titleImageContainer.width = titleImage.width;
			titleImageContainer.addChild(titleImage);
			titleImage.y = 15;
		}
		
		private function showLoginStuff():void {
			// join wall submit button
			if(this.master.login_on) loginButton.enabled = false;
			loginButton.label = 'Log in with Facebook';
			loginButton.height = 60;
			loginButton.addEventListener(MouseEvent.CLICK, doFBLogin);
			var loginButtonContainer:Group = new Group;
			loginButtonContainer.addElement(loginButton);
			this.mainContent.addElement(loginButtonContainer);	
		}
		
		// attempt to log into facebook
		private function doFBLogin(e:MouseEvent):void {
			if(this.master.login_on) Facebook.login(handleFBLogin, {'perms':'read_stream, publish_stream, user_location, email'});
			else {
				var locations:Array = [
					{'name':'New York, New York'},
					{'name':'Nashville, TN'},
					{'name':'Kalamazoo, Michigan'},
					{'name':'Santa Monica, California'},
					{'name':'Honolulu, Hawaii'},
					{'name':'Toronto, Ontario'},
					{'name':'Princeton, New Jersey'},
					{'name':'Miami, Florida'},
					{'name':'Austin, Texas'}
				];
				user.setFacebookData({'id':Math.ceil(Math.random() * 10), 'location':locations[Math.ceil(Math.random()*locations.length)-1] });
				user.login(handleLocalLogin);
			}
		}
		
		// process initial facebook data
		private function handleFBLogin(session:Object, fail:Object):void {
			if(session != null) {				
				Facebook.api("/me", getMeHandler);
			} else {
				loginButton.enabled = true;
				spinLogo();
				//Alert.show("Something went wrong logging into Facebook.", "Oops!");
			}
		}
		
		// log into local site
		private function getMeHandler(result:Object,fail:Object):void {
			user.setFacebookData(result);
			user.login(handleLocalLogin);
		}
		
		private function setStatus():void {
			Facebook.postData('/me/feed', setStatusHandler, {'message':'testing'});
		}
		
		// log into local site
		private function setStatusHandler(result:Object,fail:Object):void {
		}

		
		// show home screen
		private function handleLocalLogin(e:Event):void {
			user.finishLogin();

			this.master.removeElement(this);
			
			// suggest user likes everchat facebook page
			if(user.num_logins == 4) oneTimeSuggestFBLike();

			// check for username and prompt if one is not set
			if(user.username == '') {
				
				popupCanvas = new PopupCanvas(this);
				PopUpManager.addPopUp(popupCanvas, this, true);
				
				var FIELD_WIDTH:int = 250;
				var FIELD_FONT_SIZE:int = 25;

				var container:VGroup = new VGroup;
				container.gap = 20;
				container.paddingBottom = container.paddingTop = container.paddingLeft = container.paddingRight = 20;
				container.horizontalAlign = 'center';
				container.width = 600;
					
				// title message
				var titleLabel:Label = new Label;
				titleLabel.text = 'Hey! You must be new here.';
				titleLabel.setStyle('fontSize', 30);
				titleLabel.setStyle('fontWeight', 'bold');
				titleLabel.setStyle('fontFamily', 'Arial');
				titleLabel.setStyle('color', 0xFFFFFF);
				container.addElement(titleLabel);
				
				// username
				var usernameLabel:Label = new Label;
				usernameLabel.text = 'Enter a name you want to go by.';
				usernameLabel.setStyle('fontSize',FIELD_FONT_SIZE);
				usernameLabel.setStyle('fontFamily', 'Arial');
				usernameLabel.setStyle('color', 0xFFFFFF);
				usernameLabel.setStyle('textAlign', 'center');
				usernameLabel.percentWidth = 100;
				container.addElement(usernameLabel);	
				
				usernameInput.setStyle("fontSize", FIELD_FONT_SIZE);
				usernameInput.width = FIELD_WIDTH;
				usernameInput.setStyle('paddingTop', 10);
				usernameInput.setStyle('paddingBottom', 10);
				usernameInput.setStyle('paddingRight', 10);
				usernameInput.setStyle('paddingLeft', 10);
				usernameInput.setStyle('textAlign', 'center');
				usernameInput.text = this.user.name;
				usernameInput.addEventListener(FlexEvent.ENTER, saveUsername);
				container.addElement(usernameInput);
				
				submitUsernameButton.label = 'Save';
				submitUsernameButton.height = 60;
				submitUsernameButton.width = 120;
				submitUsernameButton.addEventListener(MouseEvent.CLICK, saveUsername);
				container.addElement(submitUsernameButton);
				
				// add form to popup window
				popupCanvas.add(container);

			// has username
			} else {
				close();
			}
		}
		
		private function saveEmailHandler(e:Event):void {
			
		}

		private function saveUsername(e:Event):void {
			var opts:Object = new Object;
			opts.username = usernameInput.text;
			opts.user_id = this.user.userID;
			loaders['saveUsername'] = new URLLoader;
			user.save(opts, loaders['saveUsername'], handleSave);
		}
		
		private function handleSave(e:Event):void {
			try {
				var response:Object = new Object;
				response = JSON.decode(loaders['saveUsername'].data);
				if(response.success == '1') {

					// do successful stuff
					user.username = response.username;
					PopUpManager.removePopUp(popupCanvas);
					close();
					
				} else {
					// do unsuccessful stuff
					Alert.show("Problem saving the username.", "Oops!");
				}
			} catch (e:TypeError) {
				trace("Could not save attributes.");
			}
		}
		
		private function close():void {
			// if the user entered a specific wall, go there. otherwise load home
			if(this.master.initial_wall_id) this.master.enterWall(new Object);
			else this.master.enterHome();
		}
		
		private function oneTimeSuggestFBLike():void {
			var request:URLRequest = new URLRequest(CONFIG.SITE_URL + "/big-facebook-like-button.png");
			var ldr:Loader = new Loader;
			ldr.load(request);
			ldr.contentLoaderInfo.addEventListener(Event.COMPLETE, oneTimeSuggestFBLike2);
			
			try {
				ldr.load(request);
			} catch (error:IOErrorEvent) {
				trace('problem loading facebook like button');				
			} catch (error:SecurityError) {
				trace(error.getStackTrace());
			}
		}
		
		private function oneTimeSuggestFBLike2(e:Event):void {
			popupCanvas = new PopupCanvas(this);
			PopUpManager.addPopUp(popupCanvas, this, true);

			var container:VGroup = new VGroup;
			container.width = 600;
			container.gap = 20;
			container.paddingBottom = container.paddingTop = container.paddingLeft = container.paddingRight = 20;
			
			// title message
			var titleLabel:RichText = new RichText;		
			
			titleLabel.textFlow = TextFlowUtil.importFromString("<span fontWeight='bold'>Hey " + this.user.first_name + "</span>! You've been here a few times. Will you go to the Everchat Facebook page and click Like?");
			titleLabel.setStyle('fontSize', 30);
			titleLabel.setStyle('fontFamily', 'Arial');
			titleLabel.setStyle('color', 0xFFFFFF);
			titleLabel.percentWidth = 100;
			container.addElement(titleLabel);
			
			// add the like button
			var likeButtonImg:DisplayObject = e.target.content;
			var likeButton:Sprite = new Sprite;
			likeButton.buttonMode = true;
			likeButton.addChild(likeButtonImg);
			likeButton.addEventListener(MouseEvent.CLICK, goToFacebookPage);
			var likeButtonContainer:UIComponent = new UIComponent;
			likeButtonContainer.addChild(likeButton);
			likeButtonContainer.x = (container.width*0.5)-(likeButtonImg.width*0.5);
			likeButton.x = (container.width*0.5)-(likeButtonImg.width*0.5);
			container.addElement(likeButtonContainer);			
			
			// add form to popup window
			popupCanvas.add(container);	
		}
		
		private function goToFacebookPage(e:MouseEvent):void {
			PopUpManager.removePopUp(popupCanvas);
			var url:String = "http://www.facebook.com/apps/application.php?id=164947616866256";
			var request:URLRequest = new URLRequest(url);
			try {
				navigateToURL(request, '_blank'); // second argument is target
			} catch (e:Error) {
				trace("Error occurred!");
			}
		}
	}
}