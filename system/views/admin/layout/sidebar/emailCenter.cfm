<cfscript>
	submenuItems = [];

	if ( hasCmsPermission( "emailcenter.customTemplates.navigate" ) ) {
		subMenuItems.append( {
			  link  = event.buildAdminLink( linkTo="emailcenter.customTemplates" )
			, title = translateResource( "cms:emailcenter.customTemplates.menu.title" )
			, active = ReFindNoCase( "^admin\.emailcenter\.customTemplates", event.getCurrentEvent() )
		} );
	}

	if ( hasCmsPermission( "emailcenter.layouts.navigate" ) ) {
		subMenuItems.append(  {
			  link  = event.buildAdminLink( linkTo="emailcenter.layouts" )
			, title = translateResource( "cms:emailcenter.layouts.menu.title" )
			, active = ReFindNoCase( "^admin\.emailcenter\.layouts", event.getCurrentEvent() )
		} );
	}

	if ( hasCmsPermission( "emailcenter.blueprints.navigate" ) ) {
		subMenuItems.append(  {
			  link  = event.buildAdminLink( linkTo="emailcenter.blueprints" )
			, title = translateResource( "cms:emailcenter.blueprints.menu.title" )
			, active = ReFindNoCase( "^admin\.emailcenter\.blueprints", event.getCurrentEvent() )
		} );
	}

	if ( hasCmsPermission( "emailcenter.systemTemplates.navigate" ) ) {
		subMenuItems.append( {
			  link  = event.buildAdminLink( linkTo="emailcenter.systemtemplates" )
			, title = translateResource( "cms:emailcenter.systemtemplates.menu.title" )
			, active = ReFindNoCase( "^admin\.emailcenter\.systemtemplates", event.getCurrentEvent() )
		} );
	}

	if ( hasCmsPermission( "emailcenter.settings.navigate" ) ) {
		subMenuItems.append(  {
			  link  = event.buildAdminLink( linkTo="emailcenter.settings" )
			, title = translateResource( "cms:emailcenter.settings.menu.title" )
			, active = ReFindNoCase( "^admin\.emailcenter\.settings", event.getCurrentEvent() )
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