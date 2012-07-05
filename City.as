package
{
	import spark.components.Label;

	public class City extends Object
	{

		public var id:uint;					// cities.id field in database
		public var name:String;				// cities.name field in database
		public var state_region:String;		// cities.state_region field in database
		public var country_code:String;		// cities.country field in database
		
		public var label:String;			// for DropDownList
		public var data:Number;				// for DropDownList
//		public var label:Label = new Label;	// needed as label for DropDownList
		
		public function City(id:uint, name:String, state_region:String, country_code:String)
		{
			super();
			
			this.id = id;
			this.name = name;
			this.state_region = state_region;
			this.country_code = country_code;
			
			this.label = this.getName();
		}
		
		public function getName():String {
			var return_me:String = this.name;
			
			if(this.country_code == 'us') return_me += ", " + this.state_region + ", USA";
			else if(this.country_code == 'jp') return_me += ", Japan";
			else if(this.country_code == 'ca') return_me += ", Canada";
			else if(this.country_code == 'gb') return_me += ", Great Britain";
			else if(this.country_code == 'ru') return_me += ", Russia";
			else if(this.country_code == 'cn') return_me += ", China";
			else if(this.country_code == 'br') return_me += ", Brazil";
			else if(this.country_code == 'de') return_me += ", Germany";
			else if(this.country_code == 'in') return_me += ", India";
			else return_me += ", " + this.country_code.toLocaleUpperCase();
			
			return return_me;
		}
		
	}
}