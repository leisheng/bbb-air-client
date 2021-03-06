package org.bigbluebutton.core
{
	import flash.events.AsyncErrorEvent;
	import flash.events.NetDataEvent;
	import flash.events.NetStatusEvent;
	import flash.events.StatusEvent;
	import flash.events.TimerEvent;
	import flash.media.Microphone;
	import flash.media.MicrophoneEnhancedMode;
	import flash.media.MicrophoneEnhancedOptions;
	import flash.media.SoundCodec;
	import flash.net.NetConnection;
	import flash.net.NetStream;
	import flash.utils.Timer;
	
	import mx.utils.ObjectUtil;

	public class VoiceStreamManager
	{
		protected var _incomingStream:NetStream = null;
		protected var _outgoingStream:NetStream = null;
		protected var _connection:NetConnection = null;
		protected var _mic:Microphone = null;
		
		protected var _heartbeat:Timer = new Timer(2000);
		
		public function VoiceStreamManager() {
			_heartbeat.addEventListener(TimerEvent.TIMER, onHeartbeat);
		}
		
		protected function onHeartbeat(event:TimerEvent):void
		{
			trace("+++ heartbeat +++");
			trace(ObjectUtil.toString(_incomingStream.audioCodec));
		}
		
		public function play(connection:NetConnection, streamName:String):void {
			_incomingStream = new NetStream(connection);
			_incomingStream.client = this;
			_incomingStream.addEventListener(NetDataEvent.MEDIA_TYPE_DATA, onNetDataEvent);
			_incomingStream.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusEvent);
			_incomingStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncErrorEvent);
			
			/*
			* Set the bufferTime to 0 (zero) for live stream as suggested in the doc.
			* http://help.adobe.com/en_US/FlashPlatform/beta/reference/actionscript/3/flash/net/NetStream.html#bufferTime
			* If we don't, we'll have a long audio delay when a momentary network congestion occurs. When the congestion
			* disappears, a flood of audio packets will arrive at the client and Flash will buffer them all and play them.
			* http://stackoverflow.com/questions/1079935/actionscript-netstream-stutters-after-buffering
			* ralam (Dec 13, 2010)
			*/
			_incomingStream.bufferTime = 0;
			_incomingStream.receiveAudio(true);
			_incomingStream.receiveVideo(false);
			_incomingStream.play(streamName);
//			_heartbeat.start();
		}
		
		protected function onNetDataEvent(event:NetDataEvent):void
		{
			trace(ObjectUtil.toString(event));
		}
		
		public function publish(connection:NetConnection, streamName:String, codec:String):void {
			_outgoingStream = new NetStream(connection);
			_outgoingStream.client = this;
			_outgoingStream.addEventListener(NetStatusEvent.NET_STATUS, onNetStatusEvent);
			_outgoingStream.addEventListener(AsyncErrorEvent.ASYNC_ERROR, onAsyncErrorEvent);
			
			setupMicrophone(codec);
			if (_mic) {
				_outgoingStream.attachAudio(_mic);
				_outgoingStream.publish(streamName, "live");
			}
		}
		
		private function noMicrophone():Boolean {
			return ((Microphone.getMicrophone() == null) || (Microphone.names.length == 0) 
				|| ((Microphone.names.length == 1) && (Microphone.names[0] == "Unknown Microphone")));
		}
		
		private function setupMicrophone(codec:String):void
		{
			if (noMicrophone()) {
				_mic = null;
				return;
			}
			
			// first try to use the enhanced microphone
			// if it doesn't work, get the regular one
			_mic = Microphone.getEnhancedMicrophone();
			if (_mic) {
				var options:MicrophoneEnhancedOptions = new MicrophoneEnhancedOptions();
				options.mode = MicrophoneEnhancedMode.FULL_DUPLEX;
				options.autoGain = false;
				options.echoPath = 128;
				options.nonLinearProcessing = true;
				_mic['enhancedOptions'] = options;
				_mic.setUseEchoSuppression(true);
			} else {
				_mic = Microphone.getMicrophone();
			}
			
			if (_mic == null) {
				trace("No microphone! <o>");
			} else {
				_mic.addEventListener(StatusEvent.STATUS, onMicStatusEvent);
				
				_mic.setLoopBack(false);
				_mic.setSilenceLevel(0, 20000);
				_mic.gain = 60;			
				
				if (codec == "SPEEX") {
					_mic.encodeQuality = 6;
					_mic.codec = SoundCodec.SPEEX;
					_mic.framesPerPacket = 1;
					_mic.rate = 16;
					trace("Using SPEEX wideband codec");
				} else {
					_mic.codec = SoundCodec.NELLYMOSER;
					_mic.rate = 8;
					trace("Using Nellymoser codec");
				}
			}
		}
		
		protected function onMicStatusEvent(event:StatusEvent):void
		{
			trace("New microphone status event");
			trace(ObjectUtil.toString(event));
			switch(event.code) {
				case "Microphone.Muted":
					break;
				case "Microphone.Unmuted":
					break;
				default:
					break;
			}
		}
		
		public function close():void {
			if (_incomingStream) {
				_incomingStream.close();
			}
			
			if (_outgoingStream) {
				_outgoingStream.attachAudio(null);
				_outgoingStream.close();
			}
		}

		protected function onNetStatusEvent(event:NetStatusEvent):void
		{
			trace(ObjectUtil.toString(event));

			switch(event.info.code) {
				case "NetStream.Play.Reset":
					break;
				case "NetStream.Play.StreamNotFound":
					break;			
				case "NetStream.Play.Failed":
					break;
				case "NetStream.Play.Start":
					break;
				case "NetStream.Play.Stop":
					break;
				case "NetStream.Publish.Start":
					break;
				case "NetStream.Buffer.Full":
					break;
				default:
					break;
			}	
		}
		
		protected function onAsyncErrorEvent(event:AsyncErrorEvent):void
		{
			trace(ObjectUtil.toString(event));
		}
		
		public function onPlayStatus(... rest):void
		{
			trace("onPlayStatus() " + ObjectUtil.toString(rest));
		}
		
		public function onMetaData(... rest):void
		{
			trace("onMetaData() " + ObjectUtil.toString(rest));
		}
		
		public function onHeaderData(... rest):void {
			trace("onHeaderData() " + ObjectUtil.toString(rest));
		}
		
	}
}