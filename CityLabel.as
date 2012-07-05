package
{	
	import spark.components.Label;
	
	public class CityLabel extends Label
	{
		public var city:City;
		
		public function CityLabel(city:City)
		{
			super();
			this.city = city;
			this.text = this.getName();
		}
		
		public function getName():String {
			return this.city.getName();
		}
	}
}