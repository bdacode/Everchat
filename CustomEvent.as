package {
	import flash.events.Event;
	
	public class CustomEvent extends Event 
	{
		/*	Place as many events as you want to include in this class  */
		public static const ROOM_ATTRIBUTES_REFRESHED:String = "room attributes refreshed";
		public static const BANNER_RETRIEVED:String = "banner retrieved";
		
		public static const CHAT_CONTROL_CLICKED:String = "chat control clicked";	// User has clicked a chat control bar and activated the chat.
		public static const CHAT_CONTROL_CLOSED:String = "chat control closed";		// User has clicked a chat control bar and activated the chat.
		
		public static const JOIN_ROOM:String = "join room";							// General join room instruction.

		public static const BROWSE_BY_CITY:String = "browse by city";				// Clicked on a city name in the Browser.

		/* 	Create properties to hold data that you want to pass with your event  
		Include as many as you like.  */
		public var data:Object;
		
		public function CustomEvent(type:String, data:Object = null) 
		{
			this.data = data;
			/*	Call the super function which fires off the event 
			set the event type, bubbling and cancelable properties  */
			super(type, false, false);
		}
		
		/*	Duplicates the instance of the event */
		override public function clone():Event
		{
			/*	This is the event that will be received by your handler function	*/
			return new CustomEvent(type, data);
		}
	}
}

/********** To use this class would look something like this **************/

/*	Dispatch event with data to be passed
dataObj.name = "test data";
dispatchEvent(new CustomEvent(CustomEvent.EXAMPLE_EVENT, dataObj));

/*	 Listen for your custom event
addEventListener(CustomEvent.EXAMPLE_EVENT, handleExample);

/*	 Handle your custom event with custom data
function handleExample(event:CustomEvent):void {
var mydata:Object = event.data;
}

/*************************************************************************/