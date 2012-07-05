package
{
	import flash.utils.ByteArray;

	public class FileChunk extends Object
	{
		public var data:ByteArray = new ByteArray;
		public var object_id:Number;			// object_id of current chunk
		public var start_object_id:Number;		// chunk is part of a group starting here
		public var end_object_id:Number;		// chunk is part of a group ending here
		public var type:String;					// identifies the type of object when processed with Wall.processNewObject()

		public function FileChunk()
		{
			super();
		}
	}
}