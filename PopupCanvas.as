package
{
	import flash.events.Event;
	import flash.utils.Timer;
	import flash.utils.clearInterval;
	import flash.utils.clearTimeout;
	import flash.utils.getTimer;
	import flash.utils.setInterval;
	import flash.utils.setTimeout;
	
	import flashx.textLayout.formats.Float;
	
	import mx.core.IVisualElement;
	import mx.events.FlexEvent;
	import mx.graphics.Stroke;
	
	import spark.components.Group;
	import spark.components.Scroller;
	import spark.components.VGroup;
	import spark.core.SpriteVisualElement;
	import spark.primitives.Rect;

	
	public class PopupCanvas extends Group {
		public var canvas:SpriteVisualElement = new SpriteVisualElement;
		public var master:Object;
		public var container:VGroup = new VGroup;
		public var containerBorder:Rect = new Rect;
		public var containerScroller:Scroller = new Scroller;
		public var containerScrollerContainer:Group = new Group;

		public function PopupCanvas(master:Object, alpha:Number=0.85) {
			super();
			this.master = master;
			this.height = master.height;
			this.width = master.width;
			
			this.container.horizontalAlign = 'center';
						
			canvas.graphics.beginFill(0x000000);
			canvas.graphics.drawRect(0,0,1500,1500);
			canvas.alpha = alpha;
			canvas.graphics.endFill();
			addElement(canvas);

			this.containerBorder.percentWidth = this.containerBorder.percentHeight = 100;
			this.containerBorder.stroke = new Stroke(0xCCCCCC,1,1);
			this.containerBorder.radiusX = containerBorder.radiusY = 15;
			this.containerScrollerContainer.addElement(containerBorder);			
			this.containerScrollerContainer.addElement(containerScroller);
			this.containerScroller.percentHeight = this.containerScroller.percentWidth = 100;
			this.containerScrollerContainer.top = 20;
			this.containerScrollerContainer.bottom = 20;
			this.containerScroller.viewport = this.container;

			addElement(containerScrollerContainer);
			addEventListener(Event.RESIZE, resize);
		}

		public function add(thing:IVisualElement):void {
			this.container.addElement(thing);
		}
		
		public function del(thing:IVisualElement):void {
			this.container.removeElement(thing);
		}
		
		public function resize(e:Event):void {
			this.containerScrollerContainer.height = master.height;
		}

		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number): void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if(this.contains(containerScrollerContainer)) {
				containerScrollerContainer.x = (this.width / 2) - (this.containerScrollerContainer.width / 2);
				this.containerScrollerContainer.top = 20;
				this.containerScrollerContainer.bottom = 20;
			}
		}		
	}
}