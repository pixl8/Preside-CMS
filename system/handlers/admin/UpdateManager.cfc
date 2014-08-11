component extends="preside.system.base.AdminHandler" output=false {

	property name="updateManagerService" inject="updateManagerService";
	property name="messageBox"           inject="coldbox:plugin:messageBox";


// LIFECYCLE EVENTS
	function preHandler( event, rc, prc ) output=false {
		super.preHandler( argumentCollection = arguments );

		if ( !hasPermission( permissionKey="updateManager.manage" ) ) {
			event.adminAccessDenied();
		}

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:updateManager" )
			, link  = event.buildAdminLink( linkTo="updateManager" )
		);

		prc.pageIcon = "cloud-download";
	}

// EVENTS
	function index( event, rc, prc ) output=false {
		prc.pageTitle    = translateResource( "cms:updateManager" );
		prc.pageSubTitle = translateResource( "cms:updateManager.subtitle" );

		prc.currentVersion = updateManagerService.getCurrentVersion();

		event.setView( "/admin/updateManager/index" );
	}

	function editSettings( event, rc, prc ) output=false {
		prc.pageTitle    = translateResource( "cms:updateManager.editSettings" );
		prc.pageSubTitle = translateResource( "cms:updateManager.editSettings.subtitle" );

		event.addAdminBreadCrumb(
			  title = translateResource( "cms:updateManager.editSettings.breadCrumb" )
			, link  = event.buildAdminLink( linkTo="updateManager.editSettings" )
		);

		prc.settings = updateManagerService.getSettings();

		event.setView( "/admin/updateManager/editSettings" );

	}

}