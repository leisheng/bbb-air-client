package org.bigbluebutton.core
{
	import flash.events.Event;
	import flash.events.HTTPStatusEvent;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLRequest;
	import flash.net.URLRequestHeader;
	import flash.net.URLRequestMethod;
	
	import mx.utils.ObjectUtil;
	
	import org.bigbluebutton.model.Config;
	import org.osflash.signals.ISignal;
	import org.osflash.signals.Signal;

	public class LoginService implements ILoginService
	{
		protected var _urlRequest:URLRequest = null;
		protected var _successJoinedSignal:Signal = new Signal();
		protected var _successGetConfigSignal:Signal = new Signal();
		protected var _unsuccessJoinedSignal:Signal = new Signal();
		protected var _joinUrl:String;
		
		public function get successJoinedSignal():ISignal {
			return _successJoinedSignal;
		}

		public function get unsuccessJoinedSignal():ISignal {
			return _unsuccessJoinedSignal;
		}
		
		public function get successGetConfigSignal():ISignal
		{
			return _successGetConfigSignal;
		}
		
		protected function fail(reason:String):void { 
			trace("Login failed. " + reason);
			unsuccessJoinedSignal.dispatch(reason);
		}			
		
		public function load(joinUrl:String):void {
			_joinUrl = joinUrl;
			
			var joinSubservice:JoinService = new JoinService();
			joinSubservice.successSignal.add(afterJoin);
			joinSubservice.unsuccessSignal.add(fail);
			joinSubservice.join(_joinUrl);
		}
		
		protected function afterJoin(urlRequest:URLRequest):void {
			_urlRequest = urlRequest;
			
			var configSubservice:ConfigService = new ConfigService();
			configSubservice.successSignal.add(afterConfig);
			configSubservice.unsuccessSignal.add(fail);
			configSubservice.getConfig(_joinUrl, _urlRequest);
		}
		
		protected function afterConfig(xml:XML):void {
			var config:Config = new Config(xml);
			successGetConfigSignal.dispatch(config);
			
			var enterSubservice:EnterService = new EnterService();
			enterSubservice.successSignal.add(afterEnter);
			enterSubservice.unsuccessSignal.add(fail);
			enterSubservice.enter(config.application.host, _urlRequest);
		}
		
		protected function afterEnter(xml:XML):void {
			if (xml.returncode == 'SUCCESS') {
				trace("Join SUCCESS");
				var user:Object = {
					username:xml.fullname, 
						conference:xml.conference, 
						conferenceName:xml.confname,
						externMeetingID:xml.externMeetingID,
						meetingID:xml.meetingID, 
						externUserID:xml.externUserID, 
						internalUserId:xml.internalUserID,
						role:xml.role, 
						room:xml.room, 
						authToken:xml.room, 
						record:xml.record, 
						webvoiceconf:xml.webvoiceconf, 
						dialnumber:xml.dialnumber,
						voicebridge:xml.voicebridge, 
						mode:xml.mode, 
						welcome:xml.welcome, 
						logoutUrl:xml.logoutUrl, 
						defaultLayout:xml.defaultLayout, 
						avatarURL:xml.avatarURL };
				user.customdata = new Object();
				if(xml.customdata)
				{
					for each(var cdnode:XML in xml.customdata.elements()){
						trace("checking user customdata: "+cdnode.name() + " = " + cdnode);
						user.customdata[cdnode.name()] = cdnode.toString();
					}
				}
				successJoinedSignal.dispatch(user);
			} else {
				trace("Join FAILED");
				
				unsuccessJoinedSignal.dispatch("Add some reason here!");
			}
		}
	}
}