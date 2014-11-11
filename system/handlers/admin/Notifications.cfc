component output="false" extends="preside.system.base.AdminHandler" {

	property name="notificationService" inject="notificationService";

	public void function preHandler( event ) output=false {
		super.preHandler( argumentCollection=arguments );

		prc.pageIcon = "fa-bell";
	}


	public void function index( event, rc, prc ) output=false {
		prc.pageTitle = translateResource( "cms:notifications.page.title" )
	}

// VIEWLETS
	private string function notificationNavPromo( event, rc, prc, args={} ) output=false {
		args.notificationCount   = notificationService.getUnreadNotificationCount( userId = event.getAdminUserId() );
		args.latestNotifications = notificationService.getUnreadTopics( userId = event.getAdminUserId() );

		return renderView( view="/admin/notifications/notificationNavPromo", args=args );
	}
}