package
{	
	import spark.components.Group;
	
	public class GameContainer extends Group
	{
		public var gameWinnersGroup:Group = new Group;
		public function GameContainer()
		{
			super();
			this.alpha = 1;
			this.clipAndEnableScrolling = true;
		}
		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number): void {
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			if(this.contains(gameWinnersGroup)) {
				gameWinnersGroup.depth = 10;
			}
		}
	}
}