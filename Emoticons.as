package
{
	// stores emoticons in convenient structure
	public class Emoticons extends Object
	{
		private var sad:Array = [];
		private var happy:Array = [];
		
		public function Emoticons()
		{
			super();
			
			happy = [
				{'text': '=]', 'sideways':true},
				{'text': '=)', 'sideways':true},
				{'text': ';D', 'sideways':true},
				{'text': ':D', 'sideways':true},
				{'text': ':]', 'sideways':true},
				{'text': ':-)', 'sideways':true},
				{'text': ':+)', 'sideways':true},
				{'text': ':o)', 'sideways':true},
				{'text': '|:o)', 'sideways':true},
				{'text': '!:o)', 'sideways':true},
//				{'text': '>=)', 'sideways':true},
//				{'text': '>=D', 'sideways':true},
				{'text': ':-D', 'sideways':true},
				{'text': ';-)', 'sideways':true},
				{'text': ':-]', 'sideways':true},
				{'text': 'B-)', 'sideways':true},
				{'text': '8-)', 'sideways':true},
				{'text': '8-]', 'sideways':true},
				{'text': '<:-)', 'sideways':true},
				{'text': ':^)', 'sideways':true},
				{'text': ':*)', 'sideways':true},
				{'text': '&:-)', 'sideways':true},
				{'text': '@:-)', 'sideways':true},
				{'text': '#:-)', 'sideways':true},
				{'text': 'O:-)', 'sideways':true},
//				{'text': '@}----', 'sideways':true},	// rose
//				{'text': '8*)', 'sideways':true},
				{'text': ':~j', 'sideways':true},
				{'text': '[:-)', 'sideways':true},
				{'text': ':n)', 'sideways':true},
				{'text': '*:O)', 'sideways':true},		// bozo the clown
				{'text': '^^', 'sideways':false},
				{'text': '(^_^)', 'sideways':false},
				{'text': '\\(^_^)/', 'sideways':false},
				{'text': '*^_^*', 'sideways':false}
			];
			
			sad = [
				{'text': '(>_<)', 'sideways':false},
				{'text': ':(', 'sideways':true},
				{'text': ':[', 'sideways':true},
				{'text': ':-(', 'sideways':true},
				{'text': ':-[', 'sideways':true},
				{'text': '=(', 'sideways':true}
			];
			
		}
		
		public function getRandomHappy():Object {
			return happy[ Math.floor(Math.random()*happy.length) ];
		}

		public function getRandomSad():Object {
			return sad[ Math.floor(Math.random()*sad.length) ];
		}
	}
}