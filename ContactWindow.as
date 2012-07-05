package
{
	import com.adobe.serialization.json.JSON;
	import com.adobe.serialization.json.JSONParseError;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.TextInput;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.Label;
	import spark.components.TextArea;
	import spark.components.TitleWindow;
	import spark.components.VGroup;
	
	public class ContactWindow extends TitleWindow
	{
		
		private var master:Group;							// thing that is calling this window
		private var config:Object;							// system-wide config object
		private var instructions:Label = new Label;			// tell user what the form is about
		private var message:TextArea = new TextArea;		// user types the message here
		private var vertical:VGroup = new VGroup;			// main layout component
		private var user:Object;							// user
		private var loaders:Object = new Object;			// store Loaders
		
		public function ContactWindow(master:Group, config:Object, form_name:String = 'Generic Form')
		{
			super();

			this.master = master;
			this.config = config;
			
			// Attributes
			this.width = 500;
			this.setStyle('cornerRadius', '7');
			this.title = form_name;
			
			vertical.paddingBottom = vertical.paddingTop = vertical.paddingLeft = vertical.paddingRight = 10;
			vertical.percentWidth = 100;

			this.message.percentWidth = 100;
			this.message.setStyle('focusSkin', null);
			this.message.setStyle('paddingRight', 8);
			this.message.setStyle('paddingLeft', 8);
			this.message.setStyle('paddingTop', 8);
			this.message.setStyle('paddingBottom', 8);
			vertical.addElement(this.message);
			
			var buttons:HGroup = new HGroup;
			buttons.percentWidth = 100;
			buttons.horizontalAlign = 'center';
			var submit_button:Button = new Button;
			submit_button.label = 'Send';
			submit_button.addEventListener(MouseEvent.CLICK, submitHandler);
			buttons.addElement(submit_button);
			var cancel_button:Button = new Button;
			cancel_button.label = 'Cancel';
			cancel_button.addEventListener(MouseEvent.CLICK, close);
			buttons.addElement(cancel_button);
			vertical.addElement(buttons);
			
			this.addElement(vertical);
			
			this.addEventListener(CloseEvent.CLOSE, close);
			this.addEventListener(Event.ADDED, messageFocusHandler);
			
		}
		
		public function messageFocusHandler(e:Event):void {
			this.message.setFocus();
		}
		
		public function set_user(user:Object):void {
			this.user = user;
		}
		
		public function set_form_name(name:String):void {
			this.title = name;
		}
		
		public function set_instructions(txt:String):void {
			this.instructions.text = txt;
			vertical.addElementAt(instructions, 0);
		}

		// Close the window.
		private function close(e:Event):void {
			PopUpManager.removePopUp(this);
		}
		
		private function submitHandler(e:MouseEvent):void {
			submit();
			close(new Event(Event.COMPLETE));
		}
		
		// Submit the info the server.
		public function submit():void {
			var variables:URLVariables = new URLVariables;

			variables.facebook_id = this.user.fbid;
			variables.user_id = this.user.userID;
			variables.email = this.user.email;
			variables.name = this.user.name;
			variables.message = this.message.text;
			
			var request:URLRequest = new URLRequest(this.config.SITE_URL + "/contact.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;
			
			loaders['submit_form'] = new URLLoader;
			loaders['submit_form'].addEventListener(Event.COMPLETE, handleSubmit);
			loaders['submit_form'].addEventListener(IOErrorEvent.IO_ERROR, ioErrorEventHandler);
			loaders['submit_form'].addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityEventHandler);
			
			try {
				loaders['submit_form'].load(request);
			} catch (err:IOErrorEvent) {
				trace(err.type);
			} catch (err:SecurityError) {
				trace(err.getStackTrace());				
			}			
		}
		
		private function handleSubmit(e:Event):void{
			try {
				var response:Object = new Object;
				response = JSON.decode(loaders['submit_form'].data);
				
				// do successful stuff
				if(response.success == '1') {
					Alert.show("Thank you!", "Good Job");					
				} else {
					// do unsuccessful stuff
					Alert.show(response.friendly_msg, "Oops!");
				}
			} catch (err:TypeError) {
				trace(err.getStackTrace());
				Alert.show("Something went wrong. We're working on it.", "Oops!");
			} catch (err:JSONParseError) {
				trace(err.getStackTrace());
				Alert.show("Something went wrong. We're working on it.", "Oops!");
			}
		}
		
		// Handle all IOErrorEvent dispatches.
		private function ioErrorEventHandler(e:IOErrorEvent):void {
			Alert.show("Something went wrong. We're working on it.", "Oops!");
		}

		// Handle all IOErrorEvent dispatches.
		private function securityEventHandler(e:IOErrorEvent):void {
			Alert.show("Something went wrong. We're working on it.", "Oops!");
		}
	}
}