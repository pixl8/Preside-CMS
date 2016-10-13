<cfscript>
	if ( isFeatureEnabled( "websiteUsers" ) ) {
		subMenuItems = [];
		if ( hasCmsPermission( "websiteUserManager.navigate" ) ) {
			subMenuItems.append( {
				  link  = event.buildAdminLink( linkTo="websiteUserManager" )
				, title = translateResource( "cms:websiteUserManager.users" )
				, active = ReFindNoCase( "\.?websiteUserManager$", event.getCurrentHandler() )
			} );
		}
		if ( isFeatureEnabled( "websiteBenefits" ) && hasCmsPermission( "websiteBenefitsManager.navigate" ) ) {
			subMenuItems.append( {
				  link  = event.buildAdminLink( linkTo="websitebenefitsmanager" )
				, title = translateResource( "cms:websiteUserManager.benefits" )
				, active = ReFindNoCase( "\.?websiteBenefitsManager$", event.getCurrentHandler() )
			} );
		}

		if ( subMenuItems.len() == 2 ) {
			WriteOutput( renderView(
				  view = "/admin/layout/sidebar/_menuItem"
				, args = {
					  active       = subMenuItems[1].active || subMenuItems[2].active
					, icon         = "fa-group"
					, title        = translateResource( 'cms:websiteUserManager' )
					, subMenuItems = subMenuItems
				  }
			) );
		} else if ( subMenuItems.len() == 1 ) {
			WriteOutput( renderView(
				  view = "/admin/layout/sidebar/_menuItem"
				, args = {
					  active = subMenuItems[1].active
					, title  = subMenuItems[1].title
					, link   = subMenuItems[1].link
					, icon   = "fa-group"
				  }
			) );
		}
	}
</cfscript>