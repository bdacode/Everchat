package
{
	public class GameFileChunk extends FileChunk
	{
		public var game_object_id:int;			// NetGroup game object that this file chunk belongs to
		public var file_num:int;				// game file id - 0=first file, 1=second file
		public var file_start_object_id:int;	// this chunk is part of a file. this is the NetGroup object replication id of the first chunk 
		public var file_end_object_id:int;		// this chunk is part of a file. this is the NetGroup object replication id of the last chunk

		public function GameFileChunk()
		{
			super();
			this.type = 'chunk';
		}
	}
}