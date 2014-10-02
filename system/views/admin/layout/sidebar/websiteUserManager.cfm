<cfscript>
	if ( hasCmsPermission( "websiteUserManager.navigate" ) || hasCmsPermission( "websiteBenefitsManager.navigate" ) ) {
		subMenu = "";
		if ( hasCmsPermission( "websiteUserManager.navigate" ) ) {
			subMenu &= renderView( view="/admin/layout/sidebar/_subMenuItem", args={
				  link  = event.buildAdminLink( linkTo="websiteUserManager" )
				, title = translateResource( "cms:websiteUserManager.users" )
			} );
		}
		if ( hasCmsPermission( "websiteBenefitsManager.navigate" ) ) {
			subMenu &= renderView( view="/admin/layout/sidebar/_subMenuItem", args={
				  link  = event.buildAdminLink( linkTo="websitebenefitsmanager" )
				, title = translateResource( "cms:websiteUserManager.benefits" )
			} );
		}

		WriteOutput( renderView(
			  view = "/admin/layout/sidebar/_menuItem"
			, args = {
				  active  = ReFindNoCase( "\.?website(user|benefits)manager$", event.getCurrentHandler() )
				, icon    = "fa-group"
				, title   = translateResource( 'cms:websiteUserManager' )
				, submenu = subMenu
			  }
		) );
	}
</cfscript>