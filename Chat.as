package
{	
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.media.SoundChannel;
	import flash.utils.setTimeout;
	
	import flashx.textLayout.conversion.TextConverter;
	
	import mx.controls.TextInput;
	import mx.core.SoundAsset;
	import mx.events.FlexEvent;
	import mx.graphics.SolidColor;
	import mx.graphics.SolidColorStroke;
	import mx.graphics.Stroke;
	import mx.utils.StringUtil;
	
	import spark.components.BorderContainer;
	import spark.components.Group;
	import spark.components.RichEditableText;
	import spark.components.Scroller;
	import spark.components.VGroup;
	import spark.primitives.Rect;
	import spark.utils.TextFlowUtil;
	
	// Chat is an input text field, a chat history box, and functionality for managing 
	// a room's public chat and private chats using those two elements.
	public class Chat extends Group
	{
		private var room:Wall;										// the room in which the object appears

		private var container:VGroup = new VGroup;					// the component is organized vertically 

		public var input_field:TextInput = new TextInput;			// user enters all chat text here
		private var chat_area_border:Rect = new Rect;				// border for the chat history area
		private var chat_area_container:Group = new Group;			// contains the scroller
		private var chat_area_scroller:Scroller = new Scroller;		// scrolls the chat area
		private var chat_controls_area:VGroup	= new VGroup;		// made of ChatControl objects which manage conversations		
		public var chat_controls:Object = new Object;				// ChatControl objects indexed by peerID
		private var active_chat_control_area:VGroup = new VGroup;	// store the active chat
		private var room_chat_control:ChatControl;					// ChatControl object for the room 
		
		private var target_facebook_id:String = '';					// used as an index for an object of ChatControls
		
		private var activated_chat_index:String;			// index of the activated chat. starts as 'room'
		public const ROOM_STR:String = 'room';
		
		// sounds
		private var plink_sound:SoundAsset; 
		private var plink_sound_channel:SoundChannel; 

		public function Chat(room:Wall)
		{
			super();
			
			this.room = room;
			
			this.container.gap = 0;
			
			this.addEventListener(CustomEvent.CHAT_CONTROL_CLICKED, controlClickHandler);
			this.addEventListener(CustomEvent.CHAT_CONTROL_CLOSED, controlClickHandler);
			this.activated_chat_index = ROOM_STR;
						
			this.chat_controls_area.percentWidth = this.active_chat_control_area.percentWidth = 100;
//			room_chat_control = new ChatControl(this, '0', ROOM_STR, this.room.url_name + '.' + this.room.CONFIG.DOMAIN);
			room_chat_control = new ChatControl(this, '0', ROOM_STR, 'Public' );
			this.chat_controls[ROOM_STR] = room_chat_control;
			this.active_chat_control_area.addElement(room_chat_control);
			this.chat_controls_area.gap = 1;
			this.chat_controls_area.paddingBottom = 6;

			// set up the input field
			this.input_field.setStyle('focusSkin', null);
			this.input_field.percentWidth = 100;
			this.input_field.addEventListener(FlexEvent.ENTER, sendMessage);
			this.input_field.id = 'input_field';
			this.input_field.setStyle('paddingLeft', 3);
			this.input_field.setStyle('paddingRight', 3);
			this.input_field.setStyle('paddingTop', 3);
			this.input_field.setStyle('paddingBottom', 3);
			this.input_field.addEventListener(Event.ADDED_TO_STAGE, addedToStageHandler);

			this.chat_area_border.percentWidth = this.chat_area_border.percentHeight = 100;
			this.chat_area_border.fill = new SolidColor(0xF2F2F2);
//			this.chat_area_border.stroke = new SolidColorStroke(0xCCCCCC, 2);
//			this.chat_area_border.radiusX = this.chat_area_border.radiusY = 3;
			this.chat_area_container.addElement(chat_area_border);
			
			// public chat box. chat_area_container encloses all the chat log elements but not the input box
			this.chat_area_container.percentWidth = this.chat_area_container.percentHeight = 100;
			this.chat_area_container.addElement(chat_area_scroller);
			this.chat_area_scroller.percentHeight = this.chat_area_scroller.percentWidth = 100;
			
			// text labels will be dropped into this chat_area VGroup
			this.chat_area_scroller.viewport = this.chat_controls[ROOM_STR].chat_area;
			
			this.container.addElement(this.active_chat_control_area);
			this.container.addElement(chat_area_container);
			this.container.addElement(this.input_field);
			
			this.container.percentHeight = this.container.percentWidth = 100;
			this.addElement(container);
		}
		
		// Do stuff after something is added to stage. setFocus() requires this.
		private function addedToStageHandler(e:Event):void {
			if(e.target.id == 'input_field') room_chat_control.highlight();
		}
		
		// Activate a conversation. 
		private function activateChat(index:String):void {

			this.input_field.setFocus();
			
			if(this.activated_chat_index == index) {
				return;	// do nothing if the active chat control was clicked
			}

			// Turn off highlighting of current activated chat.
			if(this.chat_controls[this.activated_chat_index] != undefined) {
				this.chat_controls[this.activated_chat_index].highlight('off');
			}
			
			(this.chat_controls[index] as ChatControl).highlight();				// highlight
			(this.chat_controls[index] as ChatControl).resetUnreadMessageCount();	// reset
			this.chat_area_scroller.viewport = (this.chat_controls[index] as ChatControl).chat_area;
			this.chat_controls_area.addElement(this.active_chat_control_area.getElementAt(0));
			this.active_chat_control_area.addElement((this.chat_controls[index] as ChatControl));
			
			chatControlsCheck();
				
			this.activated_chat_index = index;	// update activated chat index
		}
		
		// To save a few pixels, only show chat_controls_area if there is something to show.
		private function chatControlsCheck():void {
			if(this.chat_controls_area.numElements > 0 && this.container.contains(this.chat_controls_area) == false) {
				this.container.addElementAt(this.chat_controls_area, 0);
			} else if(this.chat_controls_area.numElements == 0 && this.container.contains(this.chat_controls_area) == true) {
				this.container.removeElement(this.chat_controls_area);
			}
		}
		
		// User clicks a chat control. Activate that chat.
		private function controlClickHandler(e:CustomEvent):void {

			var index:String = e.data.chat_index;

			if(e.type == CustomEvent.CHAT_CONTROL_CLICKED) {

				// This event is fired even if the close button is clicked, so check for close button and ignore.
				if(e.data.target_id.length > 0 && (e.data.target_id as String).substr(0, 5) == 'close') return;
				this.activateChat(index);
				
			// Remove the control and text history areas from display lists.
			} else if(e.type == CustomEvent.CHAT_CONTROL_CLOSED) {

				if(this.activated_chat_index == index) {
					this.activateChat(this.ROOM_STR);				
				}
				this.chat_controls_area.removeElement(this.chat_controls[index]);
				chatControlsCheck();
			}
		}
		
		private function sendMessage(e:FlexEvent):void{
			
			// Don't accept strings made only of spaces.
			if(StringUtil.trim(this.input_field.text).length == 0) return;

			// create the message
			var message:Object = new Object();
			if(this.activated_chat_index == this.ROOM_STR) {			// public chat

				message.type = 'public chat';
				
			} else if(this.activated_chat_index.length > 0) {		// private chat
				
				message.type = 'private chat';
				message.target_facebook_id = (this.chat_controls[ this.activated_chat_index ] as ChatControl).facebook_id;
			}

			message.sender_peer_id = this.room.netConnection.nearID;
			message.sender_facebook_id = this.room.user.fbid;
			message.message = this.input_field.text;	
			message.sender_username = this.room.user['username'];
			message.force_unique = Math.random() * 999999999;	// NetGroup.post() prevents duplicate messages. This ensures it is unique.

			// post the message
			this.room.netGroup.post(message);
			this.room.receiveMessage(message);

			this.input_field.text = "";						// clear
		}
		
		// Append chat to main chat window.
		public function processIncomingMessage(message:Object):void {
			
			// msg:String, username:String
			var message_display:RichEditableText = new RichEditableText;
			message_display.editable = false;
			message_display.focusEnabled = false
			message_display.selectable = false;
			message_display.setStyle('fontSize', 11);

			message.message = message.message.replace(/\b(https?|ftp|file):\/\/[\-A-Z0-9+&@#\/%?=~_|!:,.;]*[A-Z0-9+&@#\/%=~_|]/ig, '  <a href="$&" target="_blank">$&</a> <span> </span>');
			message_display.textFlow = TextFlowUtil.importFromString('<span fontWeight="bold" color="#444444">' + message.sender_username + ' </span>  <span> </span> ' + message.message);
			message_display.percentWidth = 100;

			var target_chat_area:VGroup;		// where is the message going?
			if(message.type == 'public chat') {
				
				target_chat_area = this.chat_controls[ROOM_STR].chat_area;

				if(this.activated_chat_index != ROOM_STR) (this.chat_controls[ROOM_STR] as ChatControl).incrementUnreadMsgCount();

			} else if(message.type == 'private chat') {

				// self
				if(this.room.netConnection.nearID == message.sender_peer_id) {
					target_chat_area = this.chat_controls[message.target_facebook_id].chat_area;
				// Chat control exists. Make sure it is displayed somewhere.
				} else if(this.chat_controls[message.sender_facebook_id] != undefined) {	// exists
					if( this.chat_controls_area.contains(this.chat_controls[message.sender_facebook_id]) == false && message.sender_facebook_id != this.activated_chat_index) {
						this.chat_controls_area.addElementAt(this.chat_controls[message.sender_facebook_id],0);
						plink_sound = new this.room.master.plink_sound() as SoundAsset; 
						plink_sound_channel = plink_sound.play(); 
					}
					target_chat_area = this.chat_controls[message.sender_facebook_id].chat_area;
				} else {														// does not exist
					this.chat_controls[message.sender_facebook_id] = new ChatControl(this, message.sender_peer_id, message.sender_facebook_id, message.sender_username);
					this.chat_controls_area.addElementAt(this.chat_controls[message.sender_facebook_id],0);	// Add the chat control to the display.						
					target_chat_area = this.chat_controls[message.sender_facebook_id].chat_area;
					plink_sound = new this.room.master.plink_sound() as SoundAsset; 
					plink_sound_channel = plink_sound.play(); 
				}
				
				// If the message is not directed to the active conversation (and is not a message this user typed), then increment the unread message count.
				if(this.activated_chat_index != message.sender_facebook_id && this.room.netConnection.nearID != message.sender_peer_id) (this.chat_controls[message.sender_facebook_id] as ChatControl).incrementUnreadMsgCount();

				chatControlsCheck();
			}
			
			var message_position:uint = (target_chat_area.numElements > 0) ? (target_chat_area.numElements) : 0;
			message_display.addEventListener(Event.ADDED, asdf);
			target_chat_area.addElementAt(message_display, message_position);
			if(target_chat_area.numElements > 200) target_chat_area.removeElementAt(0);	// limit the history to lower overhead
		}		
		
		private function asdf(e:Event):void {
			this.chat_area_scroller.verticalScrollBar.value = this.chat_area_scroller.verticalScrollBar.maximum;

		}
		// Open a new chat or activate it if it already exists.
		public function open(peer_id:String, facebook_id:String, username:String):void {
			
			// If the chat doesn't exist, create it.
			if(this.chat_controls[facebook_id] == undefined) this.chat_controls[facebook_id] = new ChatControl(this, peer_id, facebook_id, username);

			// Activate the chat control.
			activateChat(facebook_id);
		}
		
		// Reset the Chat object.
		public function exit():void {
			if((this.chat_controls[this.ROOM_STR] as ChatControl).chat_area.numElements > 0) (this.chat_controls[this.ROOM_STR] as ChatControl).chat_area.removeAllElements();
			this.activateChat(this.ROOM_STR);			
			if(this.chat_controls_area.numElements > 0) this.chat_controls_area.removeAllElements();
			this.chatControlsCheck();
		}
	}
}