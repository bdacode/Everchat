package
{
	import com.adobe.serialization.json.JSON;
	
	import flash.display.Bitmap;
	import flash.display.Loader;
	import flash.events.DataEvent;
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.net.FileFilter;
	import flash.net.FileReference;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import mx.collections.ArrayCollection;
	import mx.collections.ArrayList;
	import mx.containers.HBox;
	import mx.controls.Alert;
	import mx.controls.DataGrid;
	import mx.controls.ProgressBar;
	import mx.controls.dataGridClasses.DataGridColumn;
	import mx.core.ClassFactory;
	import mx.core.IFactory;
	import mx.core.UIComponent;
	import mx.graphics.SolidColorStroke;
	import mx.graphics.Stroke;
	import mx.managers.PopUpManager;
	
	import spark.components.Button;
	import spark.components.CheckBox;
	import spark.components.DataGroup;
	import spark.components.DropDownList;
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.Label;
	import spark.components.TextInput;
	import spark.components.VGroup;
	import spark.primitives.Rect;
	
	public class WallAdminScreen extends Group
	{
		private var wall:Wall;
		
		// form elements
		public var passwordInput:TextInput = new TextInput;
		public var gameOnCheckbox:CheckBox = new CheckBox;
		public var include_in_search_checkbox:CheckBox = new CheckBox;
		public var city_directory_dropdown:DropDownList = new DropDownList;
		public var adminScreenSubmit:Button = new Button;
		public var adminScreenCancel:Button = new Button;
		public var loaders:Object = new Object;					// separate loaders into object
		public var uploaded_banner_loader:Loader;				// needs to be public so room can access 
		private var bannerLabel:Label = new Label;				// if there is no banner, this message is displayed in the banner outline
		private var bannerContainer:Group = new Group;			// holds banner image in placeholder
		public var bannerAction:String = 'none';				// options are 'none', 'clear', and 'new' - submitted with form
		private var bannerRow2:HGroup = new HGroup;				// banner placeholder buttons 'Upload' and 'Clear'
		private var bannerClearButton:Button = new Button;		// clears the banner in the form
		private var bannerLabelContainer:VGroup = new VGroup;
		public var uploadedBannerContainer:UIComponent = new UIComponent;
		public var bannerFileReference:FileReference = new FileReference;
		private var bannerStroke:Rect = new Rect;				// banner placeholder stroke border
				
		// banned users list
		public var bannedUsers:ArrayList = new ArrayList;		// user_id's of users banned from this wall
		private var bannedUser:Object;							// stores basic info about a banned user and is an element of bannedUsers
		
		public function WallAdminScreen(wall:Wall) {
			super();
			
			this.wall = wall;	// parent
			
			var vertical:VGroup = new VGroup;			
			vertical.paddingBottom = vertical.paddingTop = vertical.paddingRight = vertical.paddingLeft = 20;
			vertical.percentWidth = 100;
			vertical.gap = 20;
			
			var FIELD_WIDTH:int = 250;
			var FIELD_FONT_SIZE:int = 20;
			
			// title
			var titleBox:HGroup = new HGroup;
			var titleLabel:Label = new Label;
			titleLabel.text = wall.getName();
			titleLabel.setStyle('fontSize', 30);
			titleLabel.setStyle('fontWeight', 'bold');
			titleLabel.setStyle('fontFamily', 'Arial');
			titleLabel.setStyle('color', 0xFFFFFF);
			vertical.addElement(titleLabel);

			// banner
			this.bannerFileReference.addEventListener(Event.SELECT, loadBannerFile);
			this.bannerFileReference.addEventListener(Event.COMPLETE, bannerFileLoaded);
			var bannerVertical:VGroup = new VGroup;
			var bannerRow1:HGroup = new HGroup;
			bannerRow1.percentWidth = 100;

			bannerStroke.percentHeight = bannerStroke.percentWidth = 100;
			bannerStroke.stroke = new SolidColorStroke(0xCCCCCC,1,1);
			bannerContainer.width = bannerVertical.width = 640;
			bannerContainer.height = 60;
			
			bannerLabel.setStyle('textAlign', 'center');
			bannerLabel.setStyle('color', 0xFFFFFF);
			bannerLabel.text = 'No banner has been set. Image should be 640x60 and will be stretched or compressed if it is not. ';
			bannerLabelContainer.percentHeight = bannerLabelContainer.percentWidth = 100;
			bannerLabelContainer.horizontalAlign = 'center';
			bannerLabelContainer.verticalAlign = 'middle';
			bannerContainer.addElement(bannerLabelContainer);
			// buttons
			var bannerUpload:Button = new Button;
			bannerUpload.label = 'Upload & Preview';
			bannerUpload.addEventListener(MouseEvent.CLICK, browseForBanner);
			bannerRow2.addElement(bannerUpload);
			// put it together
			bannerRow1.addElement(bannerContainer);
			bannerVertical.addElement(bannerRow1);
			bannerVertical.addElement(bannerRow2);
			vertical.addElement(bannerVertical);
			
			bannerClearButton.label = 'Clear';

			if(this.wall.banner_file_id) {
				bannerContainer.addElement(this.wall.bannerContainer);
				showClearBannerButton();
			} else {
				showBannerPlaceholder();
			}
				
			// password protection
			var passwordVertical:VGroup = new VGroup;
			if(wall.getPassword().length > 0) passwordInput.text = wall.CONFIG.WALL_PASS_NO_CHANGE;
			var passwordLabel:Label = new Label;
			passwordLabel.text = 'Require a password by entering one here. For no password, leave it blank. ';
			passwordLabel.setStyle('fontFamily', 'Arial');
			passwordLabel.setStyle('color', 0xFFFFFF);
			passwordVertical.addElement(passwordLabel);	
			passwordInput.displayAsPassword = true;
			passwordInput.width = FIELD_WIDTH;
			passwordVertical.addElement(passwordInput);	// end password protection
			vertical.addElement(passwordVertical);
			
			// Create searchable option.
			include_in_search_checkbox.label = 'Include in search';
			include_in_search_checkbox.selected = (wall.include_in_search) ? true : false;
			include_in_search_checkbox.setStyle('fontSize',FIELD_FONT_SIZE);
			include_in_search_checkbox.setStyle('fontFamily', 'Arial');
			include_in_search_checkbox.setStyle('color', 0xFFFFFF);
			vertical.addElement(include_in_search_checkbox);

			// Create city directory include option.
			city_directory_dropdown.dataProvider = new Cities;
			city_directory_dropdown.requireSelection = false;
			city_directory_dropdown.width = 300;
			city_directory_dropdown.setStyle('rollOverColor', 0xCCCCCC);
			city_directory_dropdown.setStyle('selectionColor', 0xCCCCCC);
			if(this.wall.city_id > 0) {	// pre-select 
				for(var i:int = 0; i < city_directory_dropdown.dataProvider.length; i++) {
					if(uint(this.wall.city_id) == city_directory_dropdown.dataProvider[i].id) {
						city_directory_dropdown.selectedIndex = i;
						break;
					}
				}
			}
			var city_directory_option_group:VGroup = new VGroup;
			var city_directory_option_label:Label = new Label;
			city_directory_option_label.text = 'Include in city directory';
			city_directory_option_label.setStyle('fontSize',FIELD_FONT_SIZE);
			city_directory_option_label.setStyle('color', 0xFFFFFF);
			city_directory_option_group.addElement(city_directory_option_label);
			city_directory_option_group.addElement(city_directory_dropdown);
			vertical.addElement(city_directory_option_group);

			// game on checkbox
			gameOnCheckbox.label = 'Play Games';
			gameOnCheckbox.selected = (wall.game_on) ? true : false;
			gameOnCheckbox.setStyle('fontSize',FIELD_FONT_SIZE);
			gameOnCheckbox.setStyle('fontFamily', 'Arial');
			gameOnCheckbox.setStyle('color', 0xFFFFFF);
			vertical.addElement(gameOnCheckbox);
			
			var buttons:HGroup = new HGroup;
			buttons.gap = 10;
			
			adminScreenSubmit.label = 'Save';
			adminScreenSubmit.height = 60;
			adminScreenSubmit.width = 120;
			buttons.addElement(adminScreenSubmit);
			
			adminScreenCancel.label = 'Cancel';
			adminScreenCancel.height = 60;
			adminScreenCancel.width = 120;
			adminScreenCancel.addEventListener(MouseEvent.CLICK, cancel);
			buttons.addElement(adminScreenCancel);
			vertical.addElement(buttons);

			this.addElement(vertical);
			getBanRecords();
		}
		
		private function showBannerPlaceholder():void {
			bannerContainer.addElement(bannerStroke);
			bannerLabelContainer.addElement(bannerLabel);
		}
		
		private function hideBannerPlaceholder():void {
			if(bannerContainer.contains(bannerLabel)) {
				bannerContainer.removeElement(bannerStroke);
				bannerLabelContainer.removeElement(bannerLabel);
			}		
		}
		
		private function showClearBannerButton():void {
			bannerRow2.addElement(bannerClearButton);
			bannerClearButton.addEventListener(MouseEvent.CLICK, clearBannerHandler);
		}

		// clear the banner 
		private function clearBannerHandler(e:MouseEvent):void {
			if(bannerContainer.contains(uploadedBannerContainer)) bannerContainer.removeElement(uploadedBannerContainer);
			else if(bannerContainer.contains(this.wall.bannerContainer)) bannerContainer.removeElement(this.wall.bannerContainer);
			bannerRow2.removeElement(bannerClearButton);
			this.bannerAction = 'clear';
			showBannerPlaceholder();
		}

		private function browseForBanner(e:MouseEvent):void {
			var bannerURLVariables:URLVariables = new URLVariables;
			bannerURLVariables.id = this.wall.id;	// assign this room id
			var fileTypes:Array = new Array();
			var imageTypes:FileFilter = new FileFilter('Images', '*.jpg;*.jpeg;*.gif;*.png');
			fileTypes.push(imageTypes);
			this.bannerFileReference.browse(fileTypes);
		}
		
		private function loadBannerFile(e:Event):void {
			this.bannerFileReference.load();
		}

		// after the FileReference loads the file into memory
		private function bannerFileLoaded(e:Event):void {
			if(this.bannerFileReference.size > this.wall.MAX_BANNER_SIZE) {
				Alert.show("Max banner size is " + int(this.wall.MAX_BANNER_SIZE/1000) + 'k');
				return;
			}
			loaders['uploaded_banner'] = new Loader;
			uploaded_banner_loader = loaders['uploaded_banner'];
			loaders['uploaded_banner'].contentLoaderInfo.addEventListener(Event.COMPLETE, bannerFileLoaded2);
			loaders['uploaded_banner'].loadBytes(this.bannerFileReference.data);
		}
		
		private function bannerFileLoaded2(e:Event):void {
			loaders['uploaded_banner'].content.width = 640;
			loaders['uploaded_banner'].content.height = 60;

			uploadedBannerContainer.addChild(loaders['uploaded_banner']);
			if(this.wall.bannerContainer != null && bannerContainer.contains(this.wall.bannerContainer)) bannerContainer.removeElement(this.wall.bannerContainer);
			hideBannerPlaceholder();
			bannerContainer.addElement(uploadedBannerContainer);			
			this.bannerAction = 'new';	// tell the form what will happen with the banner
			showClearBannerButton();
		}
		
		// remove the admin screen
		private function cancel(e:MouseEvent):void {
			this.bannerAction = 'none';
			PopUpManager.removePopUp(wall.popupCanvas);
			giveBannerBack();
			if(this.wall.banner_file_id > 0 && this.wall.titleBar.contains(this.wall.bannerContainer) == false) 
				this.wall.titleBar.addElement(this.wall.bannerContainer);
		}
		
		// the banner is on the wall initially and is moved to this (WallAdminScreen).
		// it needs to be moved back. 
		public function giveBannerBack():void {
			if(this.wall.bannerContainer != null && this.bannerContainer.contains(this.wall.bannerContainer)) {
				this.wall.titleBar.addElement(this.wall.bannerContainer);
			}
		}
		
		private function unbanUserHandler(e:Event):void {
			bannedUsers.removeItem(e.target.data);
			deleteBanRecord(e.target.user_id);
		}
		
		// add a record to banned_users indicating a user is banned from a room
		private function deleteBanRecord(id:String):void {
			var variables:URLVariables = new URLVariables;
			
			variables.wall_id = wall.id;
			variables.user_id = id;
			variables.action = 'unban';

			var request:URLRequest = new URLRequest(wall.CONFIG.SITE_URL + "/ban.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;

			loaders['unban'] = new URLLoader;
			loaders['unban'].addEventListener(Event.COMPLETE, handleDeleteBanRecord);
			//loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			try {
				loaders['unban'].load(request);
			} catch (error:IOErrorEvent) {
				Alert.show("There was a problem contacting the server. ", "Oops!");
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}			
		}
		
		private function handleDeleteBanRecord(event:Event):void{
			try {
				var response:Object = new Object;
				response = JSON.decode(loaders['unban'].data);
				
				// do successful stuff
				if(response.success == '1') {
					Alert.show("Successfully unbanned.", "Good Job");					
				} else {
					// do unsuccessful stuff
					Alert.show(response.friendly_msg, "Oops!");
				}
			} catch (e:TypeError) {
				trace("Could not unban user. " + e.getStackTrace());
			}				
		}
		
		// get ban records
		private function getBanRecords():void {
			var variables:URLVariables = new URLVariables;
			
			variables.wall_id = wall.id;
			variables.action = 'get';
			
			var request:URLRequest = new URLRequest(wall.CONFIG.SITE_URL + "/ban.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;
			
			loaders['get_bans'] = new URLLoader;
			loaders['get_bans'].addEventListener(Event.COMPLETE, handleGetBans);
			//loader.addEventListener(IOErrorEvent.IO_ERROR, errorHandler);
			
			try {
				loaders['get_bans'].load(request);
			} catch (error:IOErrorEvent) {
				Alert.show("There was a problem contacting the server. ", "Oops!");
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}			
		}
		
		// do something with the ban list data
		private function handleGetBans(event:Event):void{
			try {
				var response:Object = new Object;
				response = JSON.decode(loaders['get_bans'].data);
				
				// do successful stuff
				if(response.success == '1') {
					for(var k:String in response.bans) {
						bannedUsers.addItem(response.bans[k]);
					}
					var bannedListGroup:VGroup = new VGroup;
					bannedListGroup.x = 350;
					bannedListGroup.y = 250;
					
					var bannedColumn:DataGridColumn = new DataGridColumn;
					bannedColumn.itemRenderer = new ClassFactory(BannedUserItem);
					bannedColumn.headerText = 'Banned';
					bannedColumn.sortable = false;
					
					var bannedList:DataGrid = new DataGrid;
					bannedList.addEventListener(BannedUserItem.UNBAN_EVENT, unbanUserHandler);
					bannedList.width = 300;
					bannedList.dataProvider = bannedUsers;
					bannedList.columns = [bannedColumn];
					bannedListGroup.addElement(bannedList);
					
					this.addElement(bannedListGroup);	
					trace(bannedUsers.length);
				} else {
					// do unsuccessful stuff
					Alert.show(response.friendly_msg, "Oops!");
				}
			} catch (e:TypeError) {
				trace("Could not get ban list. " + e.getStackTrace());
			}				
		}
	}
}