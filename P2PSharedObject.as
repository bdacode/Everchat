package
{
	// P2PSharedObject downloads a file directly from the server and splits it into chunks.
	// The chunks are stored in 'chunks' and can then be replicated to the group. 
	
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IOErrorEvent;
	import flash.events.SecurityErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.ByteArray;
	
	[Event(name="complete",type="flash.events.Event")]
	public class P2PSharedObject extends EventDispatcher
	{
		
		public var file_size:Number = 0;			// size of file in bytes
		public var num_packets:uint = 0;			// number of packets or chunks
		public var file_num:int;					// identify this file in a group of files
		public var data:ByteArray = new ByteArray;	// store file
		public var chunks:Object = new Object();	// chunks of ByteArrays
		public var url:String = new String;			// remote location of file
		public var loader:URLLoader;				// loader for file
		private var chunkSize:int = 32000;			// size of packets or chunks
		public var start_object_id:int;				// NetGroup object replication index for first chunk
		public var end_object_id:int;				// NetGroup object replication index for last chunk
		public var file_type:String = new String;	// mp3, jpg, etc
		private var game_object_id:int;				// object_id of the game this file relates to
		public var sharedObjectsIndex:int;			// stores the index in the sharedObjects array so that it can be deleted
		public var type:String;						// type of shared object: 'game', 'banner'
		public var banner_file_id:int = 0;
		
		public function P2PSharedObject() {
		}
		
		public function setGameObjectID(game_object_id:int):void {
			this.game_object_id = game_object_id;
		}
		
		// initialize variables 
		public function setMeta(o:Object):void {
			if(this.type == 'game') {
				this.file_size = o.file_size;
				this.file_num = o.file_num;
				this.start_object_id = o.start_object_id;
				this.end_object_id = o.end_object_id;
				this.num_packets = Math.ceil(this.file_size/this.chunkSize);
				this.file_type = o.file_type;
				this.url = o.url;
			} else if(this.type == 'banner') {
				this.file_size = o.file_size;
				this.num_packets = Math.ceil(this.file_size/this.chunkSize);
			}
		}
		
		public function downloadFile():void {
			var request:URLRequest = new URLRequest(url);
			request.method = URLRequestMethod.GET;
			loader = new URLLoader;
			loader.dataFormat = URLLoaderDataFormat.BINARY;		// loader.data will be a ByteArray
			loader.addEventListener(Event.COMPLETE, downloadFileComplete);
			loader.addEventListener(IOErrorEvent.IO_ERROR, ioErrorHandler);
			loader.addEventListener(SecurityErrorEvent.SECURITY_ERROR, securityErrorHandler)

			try {
				loader.load(request);
			} catch (error:SecurityError) {
				trace("A SecurityError has occurred.");
			}
		}
		
		private function ioErrorHandler(e:IOErrorEvent):void {
			trace(typeof(e) + ' ' + e);
		}
		
		private function securityErrorHandler(e:SecurityErrorEvent):void {
			trace(typeof(e) + ' ' + e);			
		}
		
		private function downloadFileComplete(e:Event):void{
			try {
				this.data = new ByteArray;
				this.data = loader.data;
				explode();

			} catch (e:TypeError) {
				trace(e.getStackTrace());
			}				
		}
		
		// split file data into chunks
		public function explode():void {
			this.chunks = new Object();
			for(var i:int = 0; i < this.num_packets; i++) {
				
				// chunk type is based on the P2PSharedObject type
				switch(this.type) {
					case 'game':
						this.chunks[i] = new GameFileChunk;
						break;
					case 'banner':
						this.chunks[i] = new BannerFileChunk;
						break;
				}
				
				// last one?
				if(i == (this.num_packets-1)) {
					this.data.readBytes(this.chunks[i].data, 0, this.data.bytesAvailable);					
				} else {
					this.data.readBytes(this.chunks[i].data, 0, this.chunkSize);
				}
				
				// chunk data also dependent on P2PSharedObject type
				if(this.type == 'game') {
					this.chunks[i].object_id = i + this.start_object_id;
					this.chunks[i].file_num = this.file_num;
					this.chunks[i].file_start_object_id = this.start_object_id;
					this.chunks[i].file_end_object_id = this.end_object_id;
					this.chunks[i].game_object_id = this.game_object_id;

				} else if(this.type == 'banner') {
					this.chunks[i].object_id = i + this.start_object_id;
					this.chunks[i].start_object_id = this.start_object_id;
					this.chunks[i].end_object_id = this.end_object_id;
					this.chunks[i].banner_file_id = this.banner_file_id;
				}
			}			
			
			dispatchEvent(new Event(Event.COMPLETE));			
		}
	}
}