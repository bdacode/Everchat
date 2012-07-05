package
{
	import com.adobe.serialization.json.JSON;
	
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import mx.collections.ArrayList;
	import mx.controls.Alert;
	import mx.controls.Button;
	import mx.controls.DataGrid;
	import mx.controls.Label;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.managers.PopUpManager;
	
	import spark.components.Group;
	import spark.components.VGroup;
	
	public class Leaderboard extends VGroup
	{
		private var loaders:Object = new Object;			// separate loaders into object
		private var home:Home;								// 
		public var leaderList:ArrayList = new ArrayList;	// user_id's of users banned from this wall
		private var vertical:VGroup = new VGroup;
		
		public function Leaderboard(home:Home)
		{
			super();
			this.home = home;
			
			this.paddingBottom = this.paddingTop = this.paddingRight = this.paddingLeft = 20;
			this.x = this.y = 20;
			
			vertical.horizontalAlign = 'center';
			
			// title message
			var titleLabel:Label = new Label;
			titleLabel.text = 'Leaderboard';
			titleLabel.setStyle('fontSize', 30);
			titleLabel.setStyle('fontWeight', 'bold');
			titleLabel.setStyle('fontFamily', 'Arial');
			titleLabel.setStyle('color', 0xFFFFFF);
			vertical.addElement(titleLabel);
			
			// cancel button
			var closeButton:Button = new Button;
			closeButton.label = 'Close';
			closeButton.addEventListener(MouseEvent.CLICK, close);
			this.vertical.addElement(closeButton);
			
			this.addElement(vertical);
			
			this.get();
		}
		
		private function close(e:Event):void {
			PopUpManager.removePopUp(home.popupCanvas);
		}
		
		// get ban records
		private function get():void {
			var request:URLRequest = new URLRequest(home.CONFIG.SITE_URL + "/leaderboard.php");
			request.method = URLRequestMethod.GET;

			loaders['leaderboard'] = new URLLoader;
			loaders['leaderboard'].addEventListener(Event.COMPLETE, handle);
			
			try {
				loaders['leaderboard'].load(request);
			} catch (error:IOErrorEvent) {
				Alert.show("There was a problem contacting the server. ", "Oops!");
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}			
		}
		
		// do something with the ban list data
		private function handle(e:Event):void{
			try {
				var response:Object = new Object;
				response = JSON.decode(loaders['leaderboard'].data);
				
				// do successful stuff
				if(response.success == '1') {
					var i:int = 1;
					for(var k:String in response.leaders) {
						response.leaders[k].rank = i;
						leaderList.addItem(response.leaders[k]);
						i++;
					}
					var leaderListGroup:VGroup = new VGroup;
					leaderListGroup.x = 375;
					leaderListGroup.y = 125;
					
					// create the columns
					var rankColumn:DataGridColumn = new DataGridColumn;
					rankColumn.dataField = 'rank';
					rankColumn.headerText = 'Rank';
					rankColumn.width = 40;
					var usernameColumn:DataGridColumn = new DataGridColumn;
					usernameColumn.dataField = 'username';
					usernameColumn.headerText = 'User';
					usernameColumn.width = 150;
					var scoreColumn:DataGridColumn = new DataGridColumn;
					scoreColumn.dataField = 'points';
					scoreColumn.headerText = 'Score';
					var locationColumn:DataGridColumn = new DataGridColumn;
					locationColumn.dataField = 'location';
					locationColumn.headerText = 'Location';
					locationColumn.width = 200;
					var memberSinceColumn:DataGridColumn = new DataGridColumn;
					memberSinceColumn.dataField = 'created';
					memberSinceColumn.headerText = 'Member Since';

					var leaderGrid:DataGrid = new DataGrid;
					leaderGrid.height = 400;
					leaderGrid.dataProvider = leaderList;
					leaderGrid.columns = [rankColumn, usernameColumn, scoreColumn, locationColumn, memberSinceColumn];
					leaderListGroup.addElement(leaderGrid);
					
					this.vertical.addElement(leaderListGroup);	

				} else {
					// do unsuccessful stuff
					Alert.show(response.friendly_msg, "Oops!");
				}
			} catch (e:TypeError) {
				trace("Could not get leaderboard. " + e.getStackTrace());
			}				
		}
	}
}