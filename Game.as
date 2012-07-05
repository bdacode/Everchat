package
{
	import flash.media.Sound;

	public class Game extends Object
	{
		public var room:Wall;							// everchat room the game is being played in. need to access the room's shared objects
		public var id:Number = 0;						// refers to database games.id
		public var game_definition_id:uint = 0;			// refers to database game_definitions.id (identifies kind of game being played)
		public var data:Object;							// stores arbitrary game information. changes depending on game_definition_id
		public var activated_time:Number;				// when the game was activated in milliseconds since Jan 1 1970. originally set on server side in games.activated_time
		public var wait_time:uint = 20000;				// milliseconds from stopGame() to showGameIntermission() to playGame()
//		public var wait_time:uint = 1;				// milliseconds from stopGame() to showGameIntermission() to playGame()
		public var game_length_time:uint;				// milliseconds from playGame() to stopGame()
		public var start_object_id:Number;				// each room has its own index of objects which is always counting up (unique id's). objects are peer shared chunks of data
														// that can be essentially anything and is identified by meta data. in 'files_meta'. it might be a file chunk or a game description,
														// for example. 'start_object_id' identifies the starting object id for the game.
		public var end_object_id:Number;				// last object id relevant to this game
		public var object_id:Number;					// object_id of the game file description
		public var files:Object;						// elements are ByteArray data of a whole file
		public var files_ready:Object = new Object;		// elements vary depending on whatever will use the 'files' elements (type will be Loader for images, MP3FileReferenceLoader for MP3s, etc). 
		public var points:uint;							// number of points winning the game is worth
		public var round_id:Number;						// refers to database rounds.id
		public var round_num:uint;						// refers to database rounds.num_games_played
		public var next_game_id:Number;					// refers to database games.next_game_id (and games.id of the next game)
		public var ready:Boolean = false;				// set to true when GameWindow.playGame() is successful. all files downloaded ok.
		
		// Trivia
		public var trivia_correct_answer_sound:Sound; 
		
		public function Game(room:Wall)
		{
			super();
			this.room = room;
		}
		
		// use a shared P2P object to initialize the game. return false if something goes terribly wrong
		public function initializeFromP2PObject(obj:Object):Boolean {
			this.activated_time = obj.activated_time;
			this.data = obj.data;
			this.end_object_id = obj.end_object_id;
			this.files = obj.files;
			this.game_definition_id = obj.game_definition_id;
			this.game_length_time = obj.game_length_time;
			this.id = obj.id;
			this.next_game_id = obj.next_game_id;
			this.object_id = obj.object_id;
			this.points = obj.points;
			this.round_id = obj.round_id;
			this.round_num = obj.round_num;
			this.start_object_id = obj.start_object_id;
			return true;
		}
		
		// determine whether all files were downloaded and assigned. does not check for correct lengths.
		public function hasAllFiles():Boolean {
			for(var i:int = this.start_object_id; i < this.end_object_id; i++) {
				if(this.room.objects[i] == undefined) {
					return false;
				}
			}
			return true;
		}
		
		// join the files
		public function implodeFiles():Boolean {
			if(this.data.num_files == 0) {
				this.ready = true;	// ready to be played
				return true;
			}
			if(hasAllFiles() == false) {
				trace("hasn't all files");
				return false;
			}
			
			for(var i:uint = uint(this.start_object_id)+1; i <= uint(this.end_object_id); i++) {
				this.files[this.room.objects[i].file_num].writeBytes(this.room.objects[i].data);
			}
			
			// validate file lengths
			for(i = 0; i < this.data.num_files; i++) {
				if(this.files[i].length != uint(this.data.files_meta[i].file_size)) return false;				
			}
			
			this.ready = true;	// ready to be played
			return true;		// ok
		}
	}
}