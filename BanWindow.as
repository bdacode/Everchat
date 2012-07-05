package
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.controls.Button;
	import mx.controls.Label;
	import mx.controls.TextInput;
	import mx.events.CloseEvent;
	import mx.managers.PopUpManager;
	
	import spark.components.HGroup;
	import spark.components.TitleWindow;
	import spark.components.VGroup;
	
	public class BanWindow extends TitleWindow
	{

		private var wall:Wall;
		private var peer_id:String;		// peer id to ban
		private var reason:TextInput = new TextInput;		// reason for ban

		public function BanWindow(wall:Wall)
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
			var ban_button:Button = new Button;
			ban_button.label = 'Ban';
			ban_button.addEventListener(MouseEvent.CLICK, ban);
			buttons.addElement(ban_button);
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

		// close the ban user window
		private function close(e:Event):void {
			PopUpManager.removePopUp(wall.ban_window);
		}
		
		// perform ban user
		private function ban(e:MouseEvent):void {
			// add entry to banned table
			wall.createBanRecord({'peer_id':this.get_peer_id(), 'reason':this.get_reason()});
			
			var message:Object = new Object();
			message.type = 'ban';
			message.peerID_to_ban = this.get_peer_id();
			wall.netGroup.post(message);
			close(new Event(Event.COMPLETE));
		}
	}
}