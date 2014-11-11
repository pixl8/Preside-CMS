component output="false" extends="preside.system.base.AdminHandler" {

	property name="notificationService" inject="notificationService";

	public void function preHandler( event ) output=false {
		super.preHandler( argumentCollection=arguments );

		prc.pageIcon = "fa-bell";
		event.addAdminBreadCrumb(
			  title = translateResource( "cms:notifications.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo="notifications" )
		);
	}


	public void function index( event, rc, prc ) output=false {
		prc.pageTitle    = translateResource( "cms:notifications.page.title" );
		prc.pageSubTitle = translateResource( "cms:notifications.page.subtitle" );

		prc.notifications = notificationService.getNotifications( userId=event.getAdminUserId(), maxRows=100, topic=rc.topic ?: "" );
	}

	public void function view( event, rc, prc ) output=false {

	}

	public void function readAction( event, rc, prc ) output=false {
		var notifications = ListToArray( rc.id ?: "" );

		if ( notifications.len() ) {
			notificationService.markAsRead( notifications, event.getAdminUserId() );
		}

		setNextEvent( url=event.buildAdminLink( linkTo="notifications" ) );
	}

	public void function dismissAction( event, rc, prc ) output=false {
		var notifications = ListToArray( rc.id ?: "" );

		if ( notifications.len() ) {
			notificationService.dismiss( notifications );
		}

		setNextEvent( url=event.buildAdminLink( linkTo="notifications" ) );
	}

	public void function multiAction( event, rc, prc ) output=false {
		switch( rc.multiAction ?: "read" ) {
			case "dismiss":
				dismissAction( argumentCollection=arguments );
				break;
			default:
				readAction( argumentCollection=arguments );
		}
	}

// VIEWLETS
	private string function notificationNavPromo( event, rc, prc, args={} ) output=false {
		args.notificationCount   = notificationService.getUnreadNotificationCount( userId = event.getAdminUserId() );
		args.latestNotifications = notificationService.getUnreadTopics( userId = event.getAdminUserId() );

		return renderView( view="/admin/notifications/notificationNavPromo", args=args );
	}
}