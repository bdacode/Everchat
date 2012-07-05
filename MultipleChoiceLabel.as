package
{
	import flash.events.Event;
	import flash.events.MouseEvent;
	
	import spark.components.Label;
	
	public class MultipleChoiceLabel extends Label
	{
		public var correct:Boolean;		// is the answer right or wrong?

		public function MultipleChoiceLabel()
		{
			super();
			this.setStyle('fontFamily', 'Lucida Sans');
			this.setStyle('fontSize', 12);
			this.setStyle('paddingRight', 30);
			this.setStyle('paddingBottom', 15);
			this.addEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			this.addEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			this.addEventListener(MouseEvent.CLICK, mouseClick);
		}
		
		public function mouseOver(e:Event):void {
			this.setStyle('fontWeight', 'bold');
		}

		public function mouseOut(e:Event):void {
			this.setStyle('fontWeight', 'normal');
		}
		
		public function mouseClick(e:Event):void {
			this.setStyle('fontWeight', 'bold');
		}
		
		public function deactivate():void {
			this.removeEventListener(MouseEvent.MOUSE_OVER, mouseOver);
			this.removeEventListener(MouseEvent.MOUSE_OUT, mouseOut);
			this.removeEventListener(MouseEvent.CLICK, mouseClick);
		}
	}
}