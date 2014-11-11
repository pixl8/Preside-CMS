component output="false" extends="preside.system.base.AdminHandler" {

	property name="notificationService" inject="notificationService";
	property name="messageBox"          inject="coldbox:plugin:messageBox";

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
		prc.notification = notificationService.getNotification( id=rc.id ?: "" );
		if ( !prc.notification.count() ) {
			setNextEvent( url=event.buildAdminLink( linkTo="notifications" ) );
		}
		notificationService.markAsRead( [ rc.id ], event.getAdminUserId() );

		prc.pageTitle    = translateResource( uri="cms:notifications.view.title" );
		prc.pageSubTitle = translateResource( uri="cms:notifications.view.subtitle", data=[ renderContent( "datetime", prc.notification.datecreated ) ] );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:notifications.view.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo="notifications.view", queryString="id=" & rc.id )
		);
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

	public void function preferences( event, rc, prc ) output=false {
		prc.pageTitle    = translateResource( uri="cms:notifications.preferences.title" );
		prc.pageSubTitle = translateResource( uri="cms:notifications.preferences.subtitle" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:notifications.preferences.breadcrumbTitle" )
			, link  = event.buildAdminLink( linkTo="notifications.preferences" )
		);

		prc.subscriptions = notificationService.getUserSubscriptions( userId=event.getAdminUserId() );
		prc.topics        = notificationService.listTopics();
	}

	public void function savePreferencesAction( event, rc, prc ) output=false {
		notificationService.saveUserSubscriptions(
			  userId = event.getAdminUserId()
			, topics = ListToArray( rc.subscriptions ?: "" )
		);

		messageBox.info( translateResource( uri="cms:notifications.preferences.saved.confirmation" ) );

		setNextEvent( url=event.buildAdminLink( linkTo="notifications" ) );
	}

// VIEWLETS
	private string function notificationNavPromo( event, rc, prc, args={} ) output=false {
		args.notificationCount   = notificationService.getUnreadNotificationCount( userId = event.getAdminUserId() );
		args.latestNotifications = notificationService.getUnreadTopics( userId = event.getAdminUserId() );

		return renderView( view="/admin/notifications/notificationNavPromo", args=args );
	}
}