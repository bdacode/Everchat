package
{
	import com.adobe.serialization.json.JSON;
	import com.adobe.serialization.json.JSONParseError;
	
	import flash.events.Event;
	import flash.events.FocusEvent;
	import flash.events.IOErrorEvent;
	import flash.events.MouseEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.net.URLVariables;
	
	import mx.controls.Alert;
	import mx.events.FlexEvent;
	import mx.graphics.SolidColor;
	
	import spark.components.Button;
	import spark.components.Group;
	import spark.components.HGroup;
	import spark.components.Label;
	import spark.components.Scroller;
	import spark.components.TextInput;
	import spark.components.VGroup;
	import spark.primitives.Rect;

	// Browser is the 3rd column room browser and search area on the Home screen.
	public class Browser extends Group
	{
	
		private var config:Object;
		private var loaders:Object = new Object;
	
		private var main:VGroup = new VGroup;
		private var background:Rect = new Rect;
		private var background_fill:SolidColor = new SolidColor(0xFFFFFF, 0.7);
		
		// search input
		private var search_input_container:VGroup = new VGroup;
		private var search_input:TextInput = new TextInput;
		private var search_input_default:String = 'Room Search';
		
		// cities browser
		private var cities:Cities = new Cities();
		private var cities_list:VGroup = new VGroup;
		private var cities_list_scroller:Scroller = new Scroller;
		private var cities_header:Label = new Label;
		private var cities_container:VGroup = new VGroup;
		
		// search results
		private var search_result_list:VGroup = new VGroup;
		private var search_result_list_scroller:Scroller = new Scroller;
		private var search_result_header:Label = new Label;
		private var search_result_container:VGroup = new VGroup;
		private var search_result_back:Button = new Button;
		
		private var last_clicked_city_name:String;
		
		public function Browser(config:Object)
		{
			super();
			
			// config
			this.config = config

			// background & corner radius
			this.percentWidth = 100;
			background.radiusX = background.radiusY = 15;
			background.percentHeight = background.percentWidth = 100;
			background.fill = background_fill;			
			this.addElement(background);
			
			this.main.percentWidth = 100;
			this.main.paddingBottom = this.main.paddingTop = this.main.paddingLeft = this.main.paddingRight = 20;
			this.main.addElement(this.search_input_container);
			this.main.addElement(cities_container);			
			this.addElement(main);
			
			this.search_input_container.addElement(this.search_input);
			this.search_input_container.percentWidth = 100;
			this.search_input_container.paddingBottom = 10;
			this.search_input.percentWidth = 100;
			this.search_input.setStyle('focusedTextSelectionColor', 0xfaed00);
			this.search_input.text = this.search_input_default;
			this.search_input.setStyle('textAlign', 'center');
			this.search_input.setStyle('focusSkin', null);
			this.search_input.setStyle('color', 0x767676);
			this.search_input.addEventListener(FlexEvent.ENTER, handleTextInputSearch);
			this.search_input.addEventListener(FocusEvent.FOCUS_IN, searchInputFocusIn);
			this.search_input.addEventListener(FocusEvent.FOCUS_OUT, searchInputFocusOut);
			
			this.search_input_container.horizontalAlign = 'center';

			// cities
			cities_container.percentWidth = 100;
			cities_header.text = 'Cities';
			cities_container.addElement(cities_header);
			cities_container.addElement(cities_list_scroller);

			cities_list = new VGroup;
			cities_list.percentWidth = 100;
			cities_list_scroller.viewport = cities_list;
			cities_list_scroller.percentWidth = 100;
			cities_list_scroller.maxHeight = 200;

			var city_label:CityLabel;
			for(var i:int = 0; i < cities.length; i++) {
				city_label = new CityLabel((cities.getItemAt(i) as City));
				city_label.percentWidth = 100;
				city_label.setStyle('color', 0x0000FF);
				city_label.setStyle('textDecoration', 'underline');
				city_label.buttonMode = true;
				city_label.addEventListener(MouseEvent.CLICK, browseCity);
				cities_list.addElement(city_label);
			}
		}
				
		// Clear the room search input.
		private function searchInputFocusIn(e:FocusEvent):void {
			if(this.search_input.text == this.search_input_default) this.search_input.text = '';
			this.search_input.setStyle('color', 0x000000);
		}
		
		// Do something, maybe.
		private function searchInputFocusOut(e:FocusEvent):void {
			if(this.search_input.text.length == 0) {
				this.search_input.text = this.search_input_default;
				this.search_input.setStyle('color', 0x767676);
			}
		}
		
		// Search based on text in the input field.
		private function handleTextInputSearch(e:FlexEvent):void {
			doSearch({'search':e.target.text});
		}
		
		private function browseCity(e:MouseEvent):void {
			this.last_clicked_city_name = (e.target as CityLabel).text;
			doSearch({'city_id': (e.target as CityLabel).city.id});
		}

		// Show city rooms or, if there is only one, join the city room.
		private function doSearch(opts:Object):void {
			var variables:URLVariables = new URLVariables;
			
			if(opts.city_id != undefined) {
				variables.city_id = opts.city_id;
			} else {
				variables.search = opts.search;
			}

			var request:URLRequest = new URLRequest(this.config.SITE_URL + "/search.php");
			request.method = URLRequestMethod.POST;
			request.data = variables;
			
			loaders['search'] = new URLLoader;
			loaders['search'].addEventListener(Event.COMPLETE, handleBrowseCity);
			loaders['search'].addEventListener(IOErrorEvent.IO_ERROR, ioErrorEventHandler);
			loaders['search'].addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityEventHandler);
			
			try {
				loaders['search'].load(request);
			} catch (err:IOErrorEvent) {
				trace(err.type);
			} catch (err:SecurityError) {
				trace(err.getStackTrace());				
			}
		}
		
		// Do something with city search result. 
		private function handleBrowseCity(e:Event):void {
			try {
				var response:Object = new Object;
				response = JSON.decode(loaders['search'].data);
				
				// Do successful stuff. Show the search result. 
				if(response.success == '1') {
					
					showSearchResult(response);

				} else { // Do unsuccessful stuff.				
					Alert.show(response.friendly_msg, this.config.OOPS);
				}
			} catch (err:TypeError) {
				trace(err.getStackTrace());
				Alert.show("Something went wrong. We're working on it.", this.config.OOPS);
			} catch (err:JSONParseError) {
				trace(err.getStackTrace());
				Alert.show("Something went wrong. We're working on it.", this.config.OOPS);
			}
		}
		
		// Hide default display and show search result.
		// Search result format: { { room_id:84, name:'name here', num_members:25 }, { room_id
		private function showSearchResult(response:Object):void {
			
			// Make the room list an array.
			var rooms:Array = new Array;
			for(var k:String in response.rooms) {
				rooms.push(response.rooms[k]);
			}

			// Check for instant entry.
			if(response.instant_entry != undefined && rooms.length == 1) {
				dispatchEvent(new CustomEvent(CustomEvent.JOIN_ROOM, {'room_id':rooms[0].room_id}));
			} else {
				
				// Hide the other displays.
				if(this.main.contains(this.cities_container)) this.main.removeElement(this.cities_container);
				this.main.addElement(search_result_container);

				// Create the search result.
				search_result_container.percentWidth = 100;
				search_result_header.text = 'Search for ' + ((response.search_string != null) ? response.search_string : this.last_clicked_city_name);
				search_result_header.setStyle('paddingBottom', 5);
				
				search_result_container.addElement(search_result_header);
				search_result_container.addElement(search_result_list_scroller);
				
				search_result_back.label = 'Back to browser';
				search_result_back.percentWidth = 100;
				search_result_back.addEventListener(MouseEvent.CLICK, closeSearch);
				search_result_container.addElement(search_result_back);
				
				search_result_list = new VGroup;
				search_result_list.percentWidth = 100;
				search_result_list.paddingBottom = 10;
				search_result_list_scroller.viewport = search_result_list;
				search_result_list_scroller.percentWidth = 100;
				search_result_list_scroller.maxHeight = 200;
				
				var search_result_label:RoomLabel;
				for(var i:int = 0; i < rooms.length; i++) {
					search_result_label = new RoomLabel;
					search_result_label.text = rooms[i].name;
					search_result_label.width = 180;
					search_result_label.maxDisplayedLines = 1;
					search_result_label.room_id = Number(rooms[i].room_id);
					search_result_label.setStyle('color', 0x0000FF);
					search_result_label.setStyle('textDecoration', 'underline');
					search_result_label.buttonMode = true;
					search_result_label.addEventListener(MouseEvent.CLICK, dispatchJoinRoomEvent);

					var search_result_row:HGroup = new HGroup;
					search_result_row.addElement(search_result_label);
					var room_member_count:Label = new Label;
					room_member_count.text = String(int(rooms[i].num_members)-1);
					search_result_row.addElement(room_member_count);
					
					search_result_list.addElement(search_result_row);
				}
				if(rooms.length == 0) { // no results
					var no_results_label:Label = new Label;
					no_results_label.text = 'Nothing is coming up for that search.';
					search_result_list.addElement(no_results_label);
				}
			}
		}
		
		private function dispatchJoinRoomEvent(e:MouseEvent):void {
			dispatchEvent(new CustomEvent(CustomEvent.JOIN_ROOM, {'room_id':e.target.room_id}));
		}
		
		private function ioErrorEventHandler(e:IOErrorEvent):void {
			
		}
		
		private function securityEventHandler(e:SecurityErrorEvent):void {
			
		}
		
		private function closeSearch(e:MouseEvent):void {
			// Hide the other displays.
			if(this.main.contains(this.search_result_container)) this.main.removeElement(this.search_result_container);
			this.main.addElement(cities_container);
		}
	}
}