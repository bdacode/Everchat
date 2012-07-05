package
{
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.Scroller;
	import spark.components.VGroup;
	
	public class CamGrid extends Group
	{
		public var camWindows:Array = new Array;	// contains Video which handles the NetStream 
		public var MAX_CAMERAS:int = 20;			// ideal maximum - not strict
		private var CAMS_PER_ROW:int = 4;			// number of CamWindows per row
		private var WINDOW_SPACE:int = 1;			// pixels between CamWindows
		private var grid:VGroup = new VGroup;		// contains HGroup elements 
//		public var numCameras:int = 0;

		public function CamGrid()
		{
			super();
			grid.gap = WINDOW_SPACE;
			
			var scroller:Scroller = new Scroller;
			scroller.viewport = grid;
			this.percentHeight = this.percentWidth = scroller.percentHeight = scroller.percentWidth = 100;

			this.addElement(scroller);	// add VGroup that contains the HGroup rows
		}
		
		// add a camera to the next open spot on the grid
		public function addCam(c:CamWindow):void {
			var row:HGroup = new HGroup;
			// if there is not a single row yet, create one
			if(grid.numElements == 0) {
				row.gap = WINDOW_SPACE;
				grid.addElement(row);
				row.addElement(c);
			} else {
				// find the next open spot
				var added:Boolean = false;
				for(var i:int = 0; i < grid.numElements && added == false; i++) {
					row = grid.getElementAt(i) as HGroup;
					if(row.numElements < 4) {
						c.x = row.numElements * c.width;
						row.gap = WINDOW_SPACE;
						row.addElement(c);
						added = true;
					}
				}
				// if it is not added, then all the rows were full. create another row
				if(!added) {
					row = new HGroup;
					grid.addElement(row);
					row.addElement(c);
				}
			}
		}
		
		// if any of the rows contains the CamWindow, remove it
		public function removeCam(c:CamWindow):void {
			var row:HGroup;
			// loop through the rows and delete it 
			for(var i:int = 0; i < grid.numElements; i++) {
				row = grid.getElementAt(i) as HGroup;
				if(row.contains(c)) {
					row.removeElement(c);
					if(row.numElements == 0) grid.removeElement(row);
				}
			}
		}
		
		// defragment the grid 
		public function shapeUp():void {

		}
	}
}