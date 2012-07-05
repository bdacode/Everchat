package
{
	import flash.display.GradientType;
	import flash.geom.Matrix;
	
	import mx.controls.Alert;
	
	import spark.components.Group;
	import spark.components.Label;
	import spark.effects.Animate;
	import spark.effects.animation.MotionPath;
	import spark.effects.animation.SimpleMotionPath;
	
	// CountdownBar is a row of elements that can be incremented and decremented
	// one by one to simulate a progress bar. Intended for user with a countdown 
	// timer. Current version is text-only but image sprite elements would make 
	// a good feature.
	// + setSize() - efficiently sets the size
	public class CountdownBar extends Group
	{
		public var mode:String = 'text';	// 'text' or 'image'
		private var countdownText:Label = new Label;
		private var countdownBar:Group = new Group;
		private var countdownBarGraphics:Array;
		private var total_time:Number;
		// remove unicode 3666, 2140 from this list 
		private var textChars:Array = ['✶','✾','❆','✿','✜','✛','☺','⚡','◕','☪','♞','▩','▧','◌','◎','▚','Ꮬ','✺','♻','♺','⤶','☮','⌚','✈','♫','♪','♬','♂','✌','☤','☀','♥','●','⊕','❤','↵','⍻','σ','φ','ζ','δ','Ω','⠿','㎏','⌘','☁','◑','⦿','⍨'];
		private var textElement:String = '-';		// this character makes up the bar
		public function CountdownBar()
		{
			super();
			this.height = 20;
			this.percentWidth = 100;
		}
		
		// gradientBar mode requires initial time in seconds
		public function init(total_time:Number = 0):void {
			if(mode == 'text') {
				setFontSize(25);
				countdownText.setStyle('color', Math.random() * 0x000FFFF);
				countdownText.height = 25;
				textElement = textChars[Math.floor(Math.random()*textChars.length)];	// choose random character
				this.addElement(countdownText);
			} else if(mode == 'gradientBar') { // gradient bar goes from 500 wide to 0 regardless of total time
				this.countdownBarGraphics = [Math.random()*0x1FFFFF, Math.random()*0x2FFFFF, Math.random()*0x3FFFFF];
				this.total_time = total_time;
				countdownBar = new Group;
				countdownBar.graphics.beginGradientFill(
					GradientType.RADIAL, 	// type
					this.countdownBarGraphics, 		// colors
					[1,1,1], 					// alphas
					[0,100,200],				// ratios
					new Matrix
				);
				countdownBar.graphics.drawRoundRect(0, 0, this.width, 20, 8);
				countdownBar.graphics.endFill();
				countdownBar.setStyle('cornerRadius', 3);
				this.addElement(countdownBar);
			}
		}
				
		public function setSize(size:Number):void {
			if(mode == 'text') {
				if(size < countdownText.text.length) {
					countdownText.text = countdownText.text.substr(0, size);
				} else {
					while(countdownText.text.length < size) {
						countdownText.text += textElement;
					}
				}
			} else if(mode == 'gradientBar') {
				countdownBar.graphics.clear();
				countdownBar.graphics.beginGradientFill(
					GradientType.RADIAL, 	// type
					this.countdownBarGraphics, 		// colors
					[1,1,1], 					// alphas
					[0,100,200],				// ratios
					new Matrix
				);
				countdownBar.graphics.drawRoundRect(0, 0, int((size/this.total_time)*this.width), 20, 8);
//trace((size/this.total_time));
				countdownBar.graphics.endFill();
			}
		}
		
		public function setFontSize(size:int):void {
			countdownText.setStyle('fontSize', size);
		}
		
		public function animate():void {
			var smp:SimpleMotionPath;	// general use			
			var pulse:Animate = new Animate(this);
			pulse.duration = 300;
			pulse.repeatCount = 0;
			pulse.repeatBehavior = 'reverse';	
			smp = new SimpleMotionPath('alpha', 0.70, 1);
			pulse.motionPaths = new Vector.<MotionPath>;
			pulse.motionPaths.push(smp);
			pulse.play();
		}
	}
}