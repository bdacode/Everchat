package
{
	import com.adobe.serialization.json.JSON;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.TextInput;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.HGroup;
	import spark.components.TitleWindow;
	import spark.components.VGroup;
	
	public class FlagWindow extends TitleWindow
	{
		
		private var wall:Wall;
		private var peer_id:String;		// peer id to flag
		private var reason:TextInput = new TextInput;		// reason for flag
		private var loaders:Object = new Object;
		
		public function FlagWindow(wall:Wall)
		{
			super();
			
			this.wall = wall;
			
			this.setStyle('cornerRadius', '7');
			
			var vertical:VGroup = new VGroup;
			vertical.paddingBottom = vertical.paddingTop = vertical.paddingLeft = vertical.paddingRight = 10;
			
			var reason_label:Label = new Label();
			reason_label.text = 'Reason:';
			vertical.addElement(reason_label);
			
			vertical.addElement(reason);
			
			var buttons:HGroup = new HGroup;
			var flag_button:Button = new Button;
			flag_button.label = 'Flag';
			flag_button.addEventListener(MouseEvent.CLICK, flag);
			buttons.addElement(flag_button);
			var cancel_button:Button = new Button;
			cancel_button.label = 'Cancel';
			cancel_button.addEventListener(MouseEvent.CLICK, close);
			buttons.addElement(cancel_button);
			vertical.addElement(buttons);
			
			this.addElement(vertical);
			
			this.addEventListener(CloseEvent.CLOSE, close);
		}
		
		public function get_peer_id():String {
			return peer_id;
		}
		
		public function set_peer_id(peer_id:String):void {
			this.peer_id = peer_id;
		}
		
		public function get_reason():String {
			return reason.text;
		}
		
		// close the flag user window
		private function close(e:Event):void {
			PopUpManager.removePopUp(wall.flag_window);
		}
		
		// perform flag user
		private function flag(e:MouseEvent):void {
			// add entry to flagned table
			createFlagRecord({'peer_id':this.get_peer_id(), 'reason':this.get_reason()});
			
			var message:Object = new Object();
			message.type = 'flag';
			message.peerID_to_flag = this.get_peer_id();
			wall.netGroup.post(message);
			close(new Event(Event.COMPLETE));
		}
		
		// add a record to flagned_users indicating a user is flagned from a room
		public function createFlagRecord(opts:Object):void {
			var variables:URLVariables = new URLVariables;
			
			variables.wall_id = wall.id;
			variables.user_id = wall.peers[opts.peer_id].userID;
			variables.reason = opts.reason;
			
			var request:URLRequest = new URLRequest(wall.CONFIG.SITE_URL + "/flag.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;

			loaders['flagRecord'] = new URLLoader;
			loaders['flagRecord'].addEventListener(Event.COMPLETE, handleCreateFlagRecord);
			//loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			try {
				loaders['flagRecord'].load(request);
			} catch (error:IOErrorEvent) {
				Alert.show("There was a problem contacting the server. ", "Oops!");
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}			
		}
		
		private function handleCreateFlagRecord(event:Event):void{
			try {
				var response:Object = new Object;
				response = JSON.decode(loaders['flagRecord'].data);
				
				// do successful stuff
				if(response.success == '1') {
					Alert.show("Flagged 'em.", "Good Job");					
				} else {
					// do unsuccessful stuff
					Alert.show(response.friendly_msg, "Oops!");
				}
			} catch (e:TypeError) {
				trace("Couldn't flag 'em. " + e.getStackTrace());
			}				
		}
	}
}