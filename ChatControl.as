package
{
	
	import flash.display.Bitmap;
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import mx.core.UIComponent;
	import mx.graphics.GradientEntry;
	import mx.graphics.LinearGradient;
	import mx.graphics.SolidColor;
	import mx.graphics.SolidColorStroke;
	
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.Label;
	import spark.components.VGroup;
	import spark.effects.Animate;
	import spark.effects.animation.MotionPath;
	import spark.effects.animation.SimpleMotionPath;
	import spark.primitives.Rect;
	
	// ChatControl objects are added when a new private message is sent or received and provide
	// methods for notification and management of private chat windows. 
	public class ChatControl extends Group
	{
		private var chat:Chat;									// the Chat instance in which this ChatControl appears
		public var facebook_id:String = '';						// facebook_id of the user to chat with
		public var peer_id:String = '';							// peer_id of the user to chat with
		
		public var chat_area:VGroup = new VGroup;				// chat history shows up here

		private var container:HGroup = new HGroup;				// the main layout is a horizontal group
		private var background:Group = new Group;				// background of area
		private var background_rect:Rect = new Rect;			// background gradient is drawn here
		private var background_gradient_1:uint = 0xCCCCCC;		// background gradient start color
		private var background_gradient_2:uint = 0xD7D7D7;		// background gradient end color		
		private var background_gradient_hi_1:uint = 0xfad200;	// background gradient start color
		private var background_gradient_hi_2:uint = 0xfaf000;	// background gradient end color
		
		private var control_name:Label = new Label;				// user or control name (it might be the room name)
		private var control_name_pulse:Animate = new Animate;	// pulse the label name when active
		
		private var unread_message_object:Group = new Group;	// number of unread messages display
		private var unread_message_bg:Group = new Group;		// number of unread messages background
		private var unread_message_bg_rect:Rect = new Rect;		// number of unread messages background rectangle
		private var unread_message_bg_color:SolidColor = new SolidColor(0x999999);	// number of unread messages background rectangle
		private var unread_message_count:Label = new Label;		// number of unread messages text

		[Embed(source="chat_close_button.png")]					// closes a private chat
		private var chat_close_image_src:Class;
		private var chat_close_image:Bitmap;
		private var chat_close_image_container:UIComponent = new UIComponent;		
		
		public function ChatControl(chat:Chat, peer_id:String, facebook_id:String, name:String)
		{
			super();
			
			// set passed arguments
			this.chat = chat;
			this.facebook_id = facebook_id;
			this.peer_id = peer_id;
			this.control_name.text = name;
			
			this.percentWidth = 100;
			this.height = 25;
			this.buttonMode = true
			this.useHandCursor = true;
			
			this.container.percentWidth = this.container.percentHeight = 100;
			this.container.verticalAlign = 'middle';
			this.container.paddingRight = this.container.paddingLeft = 5;
			this.container.gap = 10;
			
			this.chat_area.paddingLeft = this.chat_area.paddingRight = this.chat_area.paddingTop = 5;
			this.chat_area.paddingTop = this.chat_area.paddingBottom = 8;
			this.chat_area.percentWidth = 100;
			this.chat_area.addEventListener(MouseEvent.CLICK, setInputFocus);
			
			// create background
			background.percentHeight = background.percentWidth = background_rect.percentHeight = background_rect.percentWidth = 100;
			this.addElement(this.background);
			
			// set up name label
			this.control_name.width = 150;
			this.control_name.maxDisplayedLines = 1;
			var control_name_container:VGroup = new VGroup;
			control_name_container.percentHeight = 100;
			control_name_container.width = 150;
			control_name_container.verticalAlign = 'middle';
			control_name_container.addElement(control_name);
			this.container.addElement(control_name_container);
			
			// add message count area
			this.unread_message_object.width = this.unread_message_bg_rect.width = 23;
			this.unread_message_object.height = this.unread_message_bg_rect.height = 19;
			this.unread_message_bg_rect.radiusX = this.unread_message_bg_rect.radiusY = 2;
			this.unread_message_bg_rect.fill = unread_message_bg_color;
			this.unread_message_bg.addElement(this.unread_message_bg_rect);
			this.unread_message_count.width = 15;
			this.unread_message_count.maxDisplayedLines = 1;
			this.unread_message_object.addElement(unread_message_bg);
			this.unread_message_count.setStyle('textAlign', 'center');
			this.unread_message_count.setStyle('color', 0xFFFFFF);
			this.unread_message_count.setStyle('fontFamily', 'Lucida Grande');
			this.unread_message_count.setStyle('fontSize', '11');
			this.unread_message_count.percentWidth = 100;
			this.unread_message_count.top = 4;
			this.unread_message_object.addElement(unread_message_count);
			this.unread_message_object.alpha = 0;
			this.container.addElement(unread_message_object);
						
			// Add close button for private chats only.
			if(this.facebook_id != this.chat.ROOM_STR) {	
				this.chat_close_image = new chat_close_image_src();
				this.chat_close_image_container.height = this.chat_close_image.height;
				this.chat_close_image_container.width = this.chat_close_image.width;
				this.chat_close_image_container.addChild(this.chat_close_image);
				var tmp:Group = new Group;
				tmp.percentWidth = 100;
				tmp.addElement(this.chat_close_image_container);
				this.container.addElement(tmp);
				this.chat_close_image_container.right = 0;
				this.chat_close_image_container.alpha = 0;
				this.chat_close_image_container.id = 'close-' + this.peer_id;
				this.addEventListener(MouseEvent.MOUSE_OVER, toggleCloseButton);
				this.addEventListener(MouseEvent.MOUSE_OUT, toggleCloseButton);
				this.chat_close_image_container.addEventListener(MouseEvent.CLICK, close);
			}
			
			this.addElement(container);

			// When clicked, activate the chat. 
			this.addEventListener(MouseEvent.CLICK, activate);
			
			// Initialize as not active. 
			this.highlight('off');
		}
		
		private function setInputFocus(e:MouseEvent):void {
			this.chat.input_field.setFocus();
		}

		// Show or hide the close button;
		private function toggleCloseButton(e:MouseEvent):void {
			if(e.type == MouseEvent.MOUSE_OVER) {
				chat_close_image_container.alpha = 1;
			} else if(e.type == MouseEvent.MOUSE_OUT) {
				chat_close_image_container.alpha = 0;				
			}
		}

		// draws a gradient on the background
		private function drawBackground():void {
			var background_gradient:LinearGradient = new LinearGradient;
//			background_rect.bottomLeftRadiusX = background_rect.bottomLeftRadiusY = background_rect.bottomRightRadiusX = background_rect.bottomRightRadiusY = 0;
			background_rect.topLeftRadiusX = background_rect.topLeftRadiusY = background_rect.topRightRadiusX = background_rect.topRightRadiusY = 0;
			background_rect.stroke = new SolidColorStroke(0xCCCCCC, 1, 1, false, 'normal', 'square', 'miter');
			background_gradient.entries = [new GradientEntry(this.background_gradient_1), new GradientEntry(this.background_gradient_2)];
			background_gradient.rotation = 270;
			background_rect.fill = background_gradient;
			background.addElement(background_rect);
		}
		
		// Add one to the unread message counter.
		public function incrementUnreadMsgCount():void {
			this.unread_message_count.text = (Number(this.unread_message_count.text)+1).toString();
			this.unread_message_object.alpha = 1;
/*			
			var s:SimpleMotionPath = new SimpleMotionPath('color', 0x0056ff, 0x767676);
			unread_message_bg_color.motionPaths = new Vector.<MotionPath>;
			control_name_pulse.motionPaths.push(s);
			control_name_pulse.target = this.unread_message_bg_color;
			control_name_pulse.duration = 1000;
			control_name_pulse.repeatCount = 1;
			control_name_pulse.play();
*/
		}
		
		// Zero the unread message counter.
		public function resetUnreadMessageCount():void {
			this.unread_message_count.text = '';
			this.unread_message_object.alpha = 0;
		}
		
		// Indicate there are unread messages by highlighting the control.
		public function highlight(mode:String = 'on'):void {
			
			if(mode == 'on') {	// highlight
				this.alpha = 0;
				this.control_name.setStyle('color', 0x444444);
				this.control_name.setStyle('fontWeight', 'bold');
				this.control_name.setStyle('fontSize', 12);
				background_rect.topLeftRadiusX = background_rect.topLeftRadiusY = background_rect.topRightRadiusX = background_rect.topRightRadiusY = 3;
				var background_gradient:LinearGradient = new LinearGradient;
				background_gradient.entries = [new GradientEntry(this.background_gradient_hi_1), new GradientEntry(this.background_gradient_hi_2)];
				background_gradient.rotation = 270;
				background_rect.fill = background_gradient;
				background_rect.stroke = null;
				this.pulseLabel();
				
			} else if(mode == 'off') {			// de-highlight
				drawBackground();
				this.control_name.setStyle('color', 0x767676);
				this.control_name.setStyle('fontWeight', 'normal');
				this.control_name.setStyle('fontSize', 12);
//				this.pulseLabel('off');
			}
		}
		
		// The user has clicked this chat control.
		public function activate(e:MouseEvent):void {
			
			// This target_id must be passed so the close button can be ignored usings its id.
			var target_id:String;
			if(e.target == null || e.target.id == null) target_id = '';
			else target_id = e.target.id;
			this.chat.dispatchEvent(new CustomEvent(CustomEvent.CHAT_CONTROL_CLICKED, {chat_index:this.facebook_id, target_id:target_id} ));
		}
		
		// Remove the control and text history areas from display lists.
		private function close(e:MouseEvent):void {			
			this.chat.dispatchEvent(new CustomEvent(CustomEvent.CHAT_CONTROL_CLOSED, {chat_index:this.facebook_id} ));
		}
		
		private function pulseLabel():void {
				var s:SimpleMotionPath = new SimpleMotionPath('alpha', 0, 1);
				control_name_pulse.motionPaths = new Vector.<MotionPath>;
				control_name_pulse.motionPaths.push(s);
				control_name_pulse.target = this;
				control_name_pulse.repeatBehavior = 'reverse';
				control_name_pulse.duration = 300;
				control_name_pulse.repeatCount = 1;
				control_name_pulse.play();
		}
		
		/* slow pulse
		private function pulseLabel(mode:String = 'on'):void {
			if(mode == 'on') {
				var s:SimpleMotionPath = new SimpleMotionPath('alpha', 1, 0.55);
				control_name_pulse.motionPaths = new Vector.<MotionPath>;
				control_name_pulse.motionPaths.push(s);
				control_name_pulse.target = this.control_name;
				control_name_pulse.repeatBehavior = 'reverse';
				control_name_pulse.duration = 1000;
				control_name_pulse.repeatCount = 0;
				control_name_pulse.play();
			} else if(mode == 'off') {
				control_name_pulse.stop();
				this.control_name.alpha = 1;
			}
		}
		*/
	}
}