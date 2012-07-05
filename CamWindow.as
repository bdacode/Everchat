package
{
	import flash.events.MouseEvent;
	import flash.media.SoundTransform;
	import flash.media.Video;
	import flash.net.NetStream;
	
	import mx.controls.Button;
	import mx.core.UIComponent;
	
	import spark.components.Group;
	import spark.components.Label;
	import spark.effects.Rotate3D;
	
	public class CamWindow extends Group {
		public var camID:int;
		public var video:Video;
		public var videoContainer:UIComponent;
		private var showVideoButton:Button;
		public var videoStream:NetStream;
		public var kickButton:Label;
		public var banButton:Label;
		public var flagButton:Label;
		public var nameLabel:Label;
		public var muteButton:Label;
		public var closeButton:Label;
		public var talkingLabel:Label;
		public var pointsLabel:Label;
		public var locationLabel:Label;
		public var user:Object;
		
		public function CamWindow(VIDEO_CELL_W:int, VIDEO_CELL_H:int) {
			super();
			this.video = new Video(VIDEO_CELL_W,VIDEO_CELL_H);
			this.width = VIDEO_CELL_W;
			this.height = VIDEO_CELL_H;
			init();
		}
		
		private function init():void {
			this.addVideo();
			this.addKickButton();
			this.addLabel();
			this.addMuteButton();
			this.addBanButton();
			this.addFlagButton();
			this.addCloseButton();
			this.addTalkingLabel();
			this.addPointsLabel();
			this.addLocationLabel();
		}
		
		public function addTalkingLabel():void {
			this.talkingLabel = new Label;
			this.talkingLabel.text = 'Talking';
			this.talkingLabel.setStyle('fontSize', 11);
			this.talkingLabel.setStyle('fontFamily','Courier New');
			this.talkingLabel.setStyle('color',0xFFFFFF);
			this.talkingLabel.setStyle('backgroundColor', 0x008000);
			this.talkingLabel.name = 'talkingLabel';
			this.talkingLabel.visible = false;
			this.talkingLabel.left = 2;
			this.talkingLabel.top = 26;
			this.addElement(talkingLabel);
		}
		
		public function addPointsLabel():void {
			this.pointsLabel = new Label;
			this.pointsLabel.text = '-';
			this.pointsLabel.setStyle('fontSize', 11);
			this.pointsLabel.setStyle('fontFamily','Courier New');
			this.pointsLabel.setStyle('color',0xFFFFFF);
			this.pointsLabel.name = 'pointsLabel';
			this.pointsLabel.visible = true;
			this.pointsLabel.left = 2;
			this.pointsLabel.top = 14;
			this.addElement(pointsLabel);
		}
		
		public function addPoints(points:Number):void {
			if(this.pointsLabel.text == '-') this.pointsLabel.text = points.toString();
			this.pointsLabel.text = (Number(this.pointsLabel.text) + points).toString();
		}
		
		public function addLocationLabel():void {
			this.locationLabel = new Label;
			this.locationLabel.text = '';
			this.locationLabel.maxDisplayedLines = 1;
			this.locationLabel.width = this.width - 15;
			this.locationLabel.setStyle('fontSize', 9);
			this.locationLabel.setStyle('fontFamily','Courier New');
			this.locationLabel.setStyle('color',0xFFFFFF);
			this.locationLabel.name = 'locationLabel';
			this.locationLabel.visible = true;
			this.locationLabel.left = 2;
			this.locationLabel.bottom = 2;
			this.addElement(locationLabel);
		}
		
		public function addCloseButton():void {
			this.closeButton = new Label;
			this.closeButton.toolTip = 'Close';
			this.closeButton.text = 'X';
			this.closeButton.setStyle('fontSize', 11);
			this.closeButton.setStyle('fontFamily','Courier New');
			this.closeButton.setStyle('color',0xFFFFFF);
			this.closeButton.name = 'closeButton';
			this.closeButton.right = 2;
			this.closeButton.top = 2;
			this.addElement(closeButton);
		}
				
		public function addKickButton():void {
			this.kickButton = new Label;
			this.kickButton.toolTip = 'Kick';
			this.kickButton.text = 'K';
			this.kickButton.setStyle('fontSize', 11);
			this.kickButton.setStyle('fontFamily','Courier New');
			this.kickButton.setStyle('color',0xFFFFFF);
			this.kickButton.name = 'kickButton';
			this.kickButton.visible = false;
			this.kickButton.right = 2;
			this.kickButton.bottom = 26;
			this.addElement(kickButton);
		}

		public function addBanButton():void {
			this.banButton = new Label;
			this.banButton.toolTip = 'Ban';
			this.banButton.text = 'B';
			this.banButton.setStyle('fontSize', 11);
			this.banButton.setStyle('fontFamily','Courier New');
			this.banButton.setStyle('color',0xFFFFFF);
			this.banButton.name = 'banButton';
			this.banButton.visible = false;
			this.banButton.right = 2;
			this.banButton.bottom = 38;
			this.addElement(banButton);
		}
		
		public function addFlagButton():void {
			this.flagButton = new Label;
			this.flagButton.toolTip = 'Flag';
			this.flagButton.text = 'F';
			this.flagButton.setStyle('fontSize', 11);
			this.flagButton.setStyle('fontFamily','Courier New');
			this.flagButton.setStyle('color',0xFFFFFF);
			this.flagButton.name = 'flagButton';
			this.flagButton.visible = true;
			this.flagButton.right = 2;
			this.flagButton.bottom = 14;
			this.addElement(flagButton);
		}
		
		public function addMuteButton():void {
			this.muteButton = new Label;
			this.muteButton.toolTip = 'Mute';
			this.muteButton.text = 'M';
			this.muteButton.setStyle('fontSize', 11);
			this.muteButton.setStyle('fontFamily','Courier New');
			this.muteButton.setStyle('color',0xFFFFFF);
			this.muteButton.name = 'muteButton';
			this.muteButton.right = 2;
			this.muteButton.bottom = 2;
			this.addElement(muteButton);
		}
		
		public function addLabel():void {
			this.nameLabel = new Label;
			this.nameLabel.text = this.camID.toString();
			this.nameLabel.maxDisplayedLines = 1;
			this.nameLabel.width = this.width - 15;
			this.nameLabel.setStyle('fontFamily','Times New Roman');
			this.nameLabel.setStyle('fontSize', 11);
			this.nameLabel.setStyle('color',0xFFFFFF);
			this.nameLabel.x = this.nameLabel.y = 2;
			this.addElement(nameLabel);
		}
		
		public function addVideo():void {
			videoContainer = new UIComponent;
			videoContainer.addChild(this.video);
			this.addElement(videoContainer);		
		}
		
		public function hideVideo():void {
			videoStream.soundTransform = new SoundTransform(0);	// mute
			removeElement(videoContainer);
			showVideoButton = new Button;
			showVideoButton.label = 'Show';
			showVideoButton.setStyle('fontSize', 13);
			showVideoButton.addEventListener(MouseEvent.CLICK, showVideoHandler);
			addElement(showVideoButton);
		}
		
		private function showVideoHandler(e:MouseEvent):void {
			showVideo();
		}

		public function showVideo():void {
			removeElement(showVideoButton);
			videoContainer.depth = -1;
			addElement(videoContainer);
			videoStream.soundTransform = new SoundTransform(1);	// un-mute
		}
		
		// animate the window 
		public function animateWinner():void {
			var r:Rotate3D = new Rotate3D;
			r.target = this;
			r.angleXFrom = 0;
			r.angleXTo = 1800;
			//			r.angleZFrom = 0;
			//			r.angleZTo = 360;
			//			r.angleYFrom = 0;
			//			r.angleYTo = 360;
			//			r.easer = null;
			r.autoCenterTransform = true;
			r.disableLayout = true;
			r.repeatCount = 1;
//			r.easer = null;
			r.duration = 2000;
			r.play();
		}
	}
}