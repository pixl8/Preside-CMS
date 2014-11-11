component output="false" extends="preside.system.base.AdminHandler" {

	property name="notificationService" inject="notificationService";

// VIEWLETS
	private string function notificationNavPromo( event, rc, prc, args={} ) output=false {
		args.notificationCount = notificationService.getUnreadNotificationCount( userId = event.getAdminUserId() );

		return renderView( view="/admin/notifications/notificationNavPromo", args=args );
	}
}