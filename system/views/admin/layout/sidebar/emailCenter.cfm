<cfscript>
	if ( hasCmsPermission( "emailcenter.navigate" ) ) {
		subMenuItems = [ {
			  link  = event.buildAdminLink( linkTo="emailcenter.layouts" )
			, title = translateResource( "cms:emailcenter.layouts.menu.title" )
			, active = ReFindNoCase( "\.?emailcenter.layouts$", event.getCurrentHandler() )
		}, {
			  link  = event.buildAdminLink( linkTo="emailcenter.systemtemplates" )
			, title = translateResource( "cms:emailcenter.systemtemplates.menu.title" )
			, active = ReFindNoCase( "\.?emailcenter.systemtemplates$", event.getCurrentHandler() )
		}, {
			  link  = event.buildAdminLink( linkTo="emailcenter.usertemplates" )
			, title = translateResource( "cms:emailcenter.usertemplates.menu.title" )
			, active = ReFindNoCase( "\.?emailcenter.usertemplates$", event.getCurrentHandler() )
		} ];

		WriteOutput( renderView(
			  view = "/admin/layout/sidebar/_menuItem"
			, args = {
				  active       = subMenuItems[1].active || subMenuItems[2].active || subMenuItems[3].active
				, icon         = "fa-envelope"
				, title        = translateResource( 'cms:emailCenter.menu.title' )
				, subMenuItems = subMenuItems
			  }
		) );
	}
</cfscript>