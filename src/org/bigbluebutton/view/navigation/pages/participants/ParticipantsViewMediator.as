package org.bigbluebutton.view.navigation.pages.participants
{
	import flash.display.DisplayObject;
	import flash.utils.Dictionary;
	
	import mx.binding.utils.BindingUtils;
	import mx.collections.ArrayCollection;
	
	import org.bigbluebutton.core.IUsersServiceSO;
	import org.bigbluebutton.core.UsersServiceSO;
	import org.bigbluebutton.model.IUserSession;
	import org.bigbluebutton.model.User;
	import org.bigbluebutton.model.UserList;
	import org.osflash.signals.ISignal;
	import org.osflash.signals.Signal;
	import org.osmf.logging.Log;
	
	import robotlegs.bender.bundles.mvcs.Mediator;
	
	public class ParticipantsViewMediator extends Mediator
	{
		[Inject]
		public var view: IParticipantsView;
		
		[Inject]
		public var userSession: IUserSession
		
		[Inject]
		public var usersServiceSO: IUsersServiceSO;
		
		protected var dataProvider:ArrayCollection;
		protected var dicUserIdtoUser:Dictionary
		protected var usersSignal:ISignal; 
		
		override public function initialize():void
		{
			Log.getLogger("org.bigbluebutton").info(String(this));

			dicUserIdtoUser = new Dictionary();
			
			dataProvider = view.list.dataProvider as ArrayCollection;
			
			usersSignal = new Signal();
			usersSignal.add(usersDataChanged);
			
			var users:ArrayCollection = userSession.userlist.users;
			for each (var user:User in users) 
			{				
				userAdded(user)
			}
	
			userSession.userlist.userAddedSignal.add(userAdded);
			userSession.userlist.userRemovedSignal.add(userRemoved);
		}
		
		private function userAdded(user:User):void
		{
			dataProvider.addItem(user);		
			dicUserIdtoUser[user.userID] = user;
			user.signal = usersSignal;
		}
		
		private function userRemoved(userID:String):void
		{
			var user:User = dicUserIdtoUser[userID] as User;
			var index:uint = dataProvider.getItemIndex(user);
			dataProvider.removeItemAt(index);
		}
		
		private function presenterChanged():void
		{
			// TODO Auto Generated method stub
			
		}
				
		private function usersDataChanged(user:User):void
		{
			trace("usersDataChanged - user:"+user)
		}
		
		override public function destroy():void
		{
			super.destroy();
			
			view.dispose();
			view = null;
			
			userSession.userlist.userAddedSignal.remove(userAdded);
			userSession.userlist.userRemovedSignal.remove(userRemoved);
		}
		
		protected function updateList(participants:Object):void
		{
			trace("test");
		}
	}
}