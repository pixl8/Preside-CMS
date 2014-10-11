<cfscript>
	if ( isFeatureEnabled( "websiteUsers" ) && ( hasCmsPermission( "websiteUserManager.navigate" ) || hasCmsPermission( "websiteBenefitsManager.navigate" ) ) ) {
		subMenuItems = [];
		if ( hasCmsPermission( "websiteUserManager.navigate" ) ) {
			subMenuItems.append( {
				  link  = event.buildAdminLink( linkTo="websiteUserManager" )
				, title = translateResource( "cms:websiteUserManager.users" )
			} );
		}
		if ( hasCmsPermission( "websiteBenefitsManager.navigate" ) ) {
			subMenuItems.append( {
				  link  = event.buildAdminLink( linkTo="websitebenefitsmanager" )
				, title = translateResource( "cms:websiteUserManager.benefits" )
			} );
		}

		WriteOutput( renderView(
			  view = "/admin/layout/sidebar/_menuItem"
			, args = {
				  active       = ReFindNoCase( "\.?website(user|benefits)manager$", event.getCurrentHandler() )
				, icon         = "fa-group"
				, title        = translateResource( 'cms:websiteUserManager' )
				, subMenuItems = subMenuItems
			  }
		) );
	}
</cfscript>