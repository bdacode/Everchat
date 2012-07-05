package
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.containers.Canvas;
	import mx.controls.Button;
	import mx.controls.Label;
	
	import spark.components.HGroup;
	import spark.components.RichText;
	import spark.components.VGroup;
	
	public class BannedUserItem extends Canvas
	{
		public static const UNBAN_EVENT:String = "unban";
		
		public var user_id:int = new int;
		private var unban_button:Button = new Button;
		private var fb_name:Label = new Label;
		private var username:Label = new Label;
		private var ban_date:Label = new Label;
		private var ban_reason:RichText = new RichText;
		public var original_object:Object = new Object;
		public function BannedUserItem()
		{
			super();
			
			this.clipContent = false;
			this.width = 300;
			unban_button.label = 'Unban';
		}
		
		// set stuff we want to display
		override public function set data(value:Object):void {
			super.data = value; //very important dont forget to set super.data when overriding set data
			user_id = value.user_id;
			fb_name.text = value.name;
			username.text = value.username;
			ban_date.text = value.ban_date;
			this.toolTip = value.ban_reason;
			init();
		}
		
		private function init():void {
			var horizontal:HGroup = new HGroup;
			horizontal.horizontalAlign = 'center';
			horizontal.percentWidth = 	fb_name.percentWidth = unban_button.percentWidth = ban_date.percentWidth =  100;
			horizontal.paddingTop = horizontal.paddingBottom = horizontal.paddingLeft = horizontal.paddingRight = 5;
			horizontal.addElement(unban_button);
			unban_button.addEventListener(MouseEvent.CLICK, unbanClickHandler);
			horizontal.addElement(username);
			horizontal.addElement(ban_date);
			this.addElement(horizontal);
		}

		// event that removes the ban
		private function unbanClickHandler(e:Event):void {
			var e:Event = new Event(UNBAN_EVENT,true);
			this.dispatchEvent(e);
		}
	}
}