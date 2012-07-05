package
{
	
	import flash.events.MouseEvent;
	
	import flashx.textLayout.formats.Float;
	import flashx.textLayout.formats.LineBreak;
	
	import mx.controls.Label;
	
	import spark.components.Button;
	import spark.components.HGroup;
	import spark.components.RichText;
	import spark.components.VGroup;
	
	public class BigAlert extends PopupCanvas {

		public var submitOK:Button = new spark.components.Button;

		public function BigAlert(master:Object, alpha:Number=0.75) {
			super(master, alpha);
			this.master = master;
		}
		
		public function show(msg:String):void {

			this.width = this.master.width;
			this.height = this.master.height;
			
			var vertGroup:VGroup = new VGroup;
			vertGroup.width = this.width;
			vertGroup.height = this.height;
			
			// message
			var row1:HGroup = new HGroup;
			row1.width = this.width;
			var titleLabel:RichText = new RichText;
			titleLabel.text = msg;
			titleLabel.setStyle('fontSize',25);
			titleLabel.setStyle('fontWeight', 'bold');
			titleLabel.setStyle('fontFamily', 'Arial');
			titleLabel.width = row1.width;
			titleLabel.setStyle('color', 0xFFFFFF);
			row1.addElement(titleLabel);
			vertGroup.addElement(row1);
			
			var row2:HGroup = new HGroup;
			row2.width = this.width;
			submitOK.label = 'OK';
			submitOK.height = 60;
			submitOK.width = 120;
			submitOK.addEventListener(MouseEvent.CLICK, closeAlert);
			row2.addElement(submitOK);
			vertGroup.addElement(row2);
			
			this.add(vertGroup);
			
			this.master.addElement(this);
		}
		
		private function closeAlert(event:MouseEvent):void {
			this.master.removeElement(this);
			delete this;
		}
	}
}