<cfscript>
	submenuItems = [];

	if ( hasCmsPermission( "emailcenter.userTemplates.navigate" ) ) {
		subMenuItems.append( {
			  link  = event.buildAdminLink( linkTo="emailcenter.usertemplates" )
			, title = translateResource( "cms:emailcenter.usertemplates.menu.title" )
			, active = ReFindNoCase( "^admin\.emailcenter\.usertemplates", event.getCurrentEvent() )
		} );
	}

	if ( hasCmsPermission( "emailcenter.systemTemplates.navigate" ) ) {
		subMenuItems.append( {
			  link  = event.buildAdminLink( linkTo="emailcenter.systemtemplates" )
			, title = translateResource( "cms:emailcenter.systemtemplates.menu.title" )
			, active = ReFindNoCase( "^admin\.emailcenter\.systemtemplates", event.getCurrentEvent() )
		} );
	}


	if ( hasCmsPermission( "emailcenter.layouts.navigate" ) ) {
		subMenuItems.append(  {
			  link  = event.buildAdminLink( linkTo="emailcenter.layouts" )
			, title = translateResource( "cms:emailcenter.layouts.menu.title" )
			, active = ReFindNoCase( "^admin\.emailcenter\.layouts", event.getCurrentEvent() )
		} );
	}

	if ( subMenuItems.len() ) {
		WriteOutput( renderView(
			  view = "/admin/layout/sidebar/_menuItem"
			, args = {
				  active       = ReFindNoCase( "^admin\.emailcenter\.", event.getCurrentEvent() )
				, icon         = "fa-envelope"
				, title        = translateResource( 'cms:emailCenter.menu.title' )
				, subMenuItems = subMenuItems
			  }
		) );
	}
</cfscript>