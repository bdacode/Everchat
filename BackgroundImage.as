package
{
	import flashx.textLayout.conversion.TextConverter;
	
	import mx.graphics.SolidColor;
	
	import spark.components.Group;
	import spark.components.Label;
	import spark.components.RichEditableText;
	import spark.components.VGroup;
	import spark.primitives.Rect;

	public class BackgroundImage extends Object
	{
		public var id:int = 0;				// files are named <id>.jpg
		public var author:String = '';		// who made it
		public var author_url:String = '';	// author's website
		public var title:String = '';		// title of image
		public var title_url:String = '';	// usually link to image
		public var description:String = '';	// something about it 
		public var url:String = '';			// a relevant url
		
		public function BackgroundImage(id:uint, author:String, author_url:String, title:String, title_url:String, description:String)
		{
			super();
			this.id = id;
			this.author = author;
			this.author_url = author_url;
			this.title = title;
			this.title_url = title_url;
			this.description = description;
		}
		
		// Returns an area with credit info about the image. 
		public function getCreditGroup():Group {

			var container:Group = new Group;
			var layout:VGroup = new VGroup;
			container.percentWidth = layout.percentWidth = 100;
			layout.verticalAlign = 'middle';
			
			var background:Rect = new Rect;
			background.radiusX = background.radiusY = 5;
			background.percentHeight = background.percentWidth = 100;
			var background_fill:SolidColor = new SolidColor(0xFFFFFF, 0.7);
			background.fill = 	background_fill;
			
			container.addElement(background);
			container.addElement(layout);
			
			// store items in a horizontal group
			layout.gap = 5;
			layout.paddingBottom = layout.paddingTop = layout.paddingLeft = layout.paddingRight = 10;

			var credit_text:String = '';
			if(this.author.length > 0) {
				var author_text:String;
				if(this.author_url.length > 0) {
					author_text = '<a href="' + this.author_url + '" target="_blank">' + this.author + '</a>';
				} else {
					author_text  = this.author;
				}
				credit_text += 'Photo credit: ' + author_text + '. ';
			}
			
			if(this.title.length > 0) {
				var title_text:String;
				if(this.title_url.length > 0) {
					title_text = '<a href="' + this.title_url + '" target="_blank">' + this.title + '</a>';
				} else {
					title_text  = this.title;
				}
				credit_text += title_text + '. ';
			}
			
			if(this.description.length > 0) {
				credit_text += this.description;
			}
			
			if(credit_text.length > 0) {
				var credit_label:RichEditableText = new RichEditableText;
				credit_label.focusEnabled = false;
				credit_label.editable = false;
				credit_label.selectable = false;
				credit_label.percentWidth = 100;
				credit_label.setStyle('fontSize', 11);
				credit_label.textFlow = TextConverter.importToFlow(credit_text, TextConverter.TEXT_FIELD_HTML_FORMAT);
				layout.addElement(credit_label);
			}
//			message.message = message.message.replace(/\b(https?|ftp|file):\/\/[\-A-Z0-9+&@#\/%?=~_|!:,.;]*[A-Z0-9+&@#\/%=~_|]/ig, '<a href="$&" target="_blank">$&</a>');
//			message_display.textFlow = TextConverter.importToFlow(message.sender_username + ': ' + message.message, TextConverter.TEXT_FIELD_HTML_FORMAT);
//			message_display.percentWidth = 100;

			return container;
		}
		
		// Determine whether there is enough information to compile a credit display. 
		public function hasCreditDisplay():Boolean {
			if(author.length + title.length > 0) return true;
			else return false;
		}
	}
}