<cfscript>
	if ( hasCmsPermission( "usermanager.navigate" ) || hasCmsPermission( "groupmanager.navigate" ) ) {
		subMenuItems = [];
		if ( hasCmsPermission( "usermanager.navigate" ) ) {
			subMenuItems.append( {
				  link  = event.buildAdminLink( linkTo='usermanager.users' )
				, title = translateResource( "cms:usermanager.users" )
			} );
		}
		if ( hasCmsPermission( "groupmanager.navigate" ) ) {
			subMenuItems.append( {
				  link  = event.buildAdminLink( linkTo='usermanager.groups' )
				, title = translateResource( "cms:usermanager.groups" )
			} );
		}

		WriteOutput( renderView(
			  view = "/admin/layout/sidebar/_menuItem"
			, args = {
				  active       = ListLast( event.getCurrentHandler(), ".") eq "usermanager"
				, icon         = "fa-group"
				, title        = translateResource( 'cms:usermanager' )
				, subMenuItems = subMenuItems
			  }
		) );
	}
</cfscript>