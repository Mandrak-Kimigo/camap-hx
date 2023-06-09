package service;
import tink.core.Error;
import Common;

class WaitingListService{

	/**
		Register someone who is outside of the group to the waiting list.
	**/
	public static function registerToWl(user:db.User,group:db.Group,message:String, ?sendEmail=true){
		var t  = sugoi.i18n.Locale.texts;

		canRegister(user,group);

		var w = new db.WaitingList();
		w.user = user;
		w.group = group;
		w.message = message;
		w.insert();

		if(sendEmail){
			//send an email to admins
			var html = t._("<p><b>::name::</b> suscribed to the waiting list of <b>::group::</b> on ::date::</p>",{
				group:group.name,
				name:user.getName(),
				date:App.current.view.hDate(Date.now())
			});
			if(message!=null && message!=""){
				html += t._("<p>He/she left this message :<br/>\"::message::\"</p>",{message:message});
			}

			for( u in service.GroupService.getGroupMembersWithRights(group,[Right.GroupAdmin,Right.Membership]) ){
				App.quickMail(
					u.email,
					user.getName() + " s'est inscrit·e à la liste d'attente.",
					html,
					group
				);
			}
		}
	}

	public static function canRegister(user:db.User,group:db.Group){
		var t  = sugoi.i18n.Locale.texts;
		
		if ( db.WaitingList.manager.select($amapId == group.id && $user == user) != null) {
			throw new Error(t._("You are already in the waiting list of this group"));
		}
		if ( db.UserGroup.manager.select($groupId == group.id && $user == user) != null) {
			throw new Error(t._("You are already member of this group."));
		}
	}

	/**
		the user cancels his request
	**/
	public static function removeFromWl(user:db.User,group:db.Group){
		var t  = sugoi.i18n.Locale.texts;
		if ( user == null) {
			throw new Error(t._("You should be logged in."));
		}

		var wl = db.WaitingList.manager.select($amapId == group.id && $user == user,true);

		if ( wl == null) {
			throw new Error(t._("You are not in the waiting list of this group"));
		}
		wl.delete();
	}


	/**
		Put a member of the group back on waiting list
	**/
	public static function moveBackToWl(user:db.User,group:db.Group,message:String){
		var t  = sugoi.i18n.Locale.texts;

		//checks
		var ug = db.UserGroup.get(user,group,true);
		if( ug==null ) throw new Error(user.getName()+" ne fait pas partie de ce groupe.");
		if( App.current.user.id==user.id ) throw new Error("Vous ne pouvez pas vous mettre vous-même en liste d'attente.");
		if(ug.hasRight(GroupAdmin)) throw new Error("Vous ne pouvez pas mettre "+user.getName()+" en liste d'attente, car c'est un administrateur du groupe.");
		var wl = db.WaitingList.manager.select($user==user && $group==group);
		if(wl!=null) throw new Error("Cette personne est déjà dans la liste d'attente.");

		ug.delete();

		var w = new db.WaitingList();
		w.user = user;
		w.group = group;
		w.message = message;
		w.insert();
	}

}