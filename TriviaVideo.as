package
{
	import flash.media.Video;
	import flash.utils.ByteArray;
	
	public class TriviaVideo extends Video
	{
		public var file:ByteArray;		// video byte array
		public function TriviaVideo(width:int=320, height:int=240)
		{
			super(width, height);
		}
	}
}