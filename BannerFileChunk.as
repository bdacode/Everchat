package
{
	public class BannerFileChunk extends FileChunk
	{
		public var banner_file_id:uint = 0;
		public function BannerFileChunk()
		{
			super();
			this.type = 'room banner chunk';
		}
	}
}