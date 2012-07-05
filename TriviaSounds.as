package
{	
	import mx.core.SoundAsset;

	public class TriviaSounds extends Object
	{
		private var correct_sounds:Array = new Array;	// array of SoundAsset instances

		[Embed(source="files/audio/trivia_correct_1.mp3")]
		private var correct_1:Class;
		[Embed(source="files/audio/trivia_correct_2.mp3")]
		private var correct_2:Class;
		
		public function TriviaSounds()
		{
			super();
			
			this.correct_sounds[0] = new correct_1() as SoundAsset;
			this.correct_sounds[1] = new correct_2() as SoundAsset;
		}
		
		// Play a random correct answer sound.
		public function correct():void {
			correct_sounds[Math.floor(Math.random()*correct_sounds.length)].play();
		}
	}
}