<cfscript>
	if ( hasCmsPermission( "usermanager.navigate" ) || hasCmsPermission( "groupmanager.navigate" ) ) {
		subMenu = "";
		if ( hasCmsPermission( "usermanager.navigate" ) ) {
			subMenu &= renderView( view="/admin/layout/sidebar/_subMenuItem", args={
				  link  = event.buildAdminLink( linkTo='usermanager.users' )
				, title = translateResource( "cms:usermanager.users" )
			} );
		}
		if ( hasCmsPermission( "groupmanager.navigate" ) ) {
			subMenu &= renderView( view="/admin/layout/sidebar/_subMenuItem", args={
				  link  = event.buildAdminLink( linkTo='usermanager.groups' )
				, title = translateResource( "cms:usermanager.groups" )
			} );
		}

		WriteOutput( renderView(
			  view = "/admin/layout/sidebar/_menuItem"
			, args = {
				  active  = ListLast( event.getCurrentHandler(), ".") eq "usermanager"
				, icon    = "fa-group"
				, title   = translateResource( 'cms:usermanager' )
				, submenu = subMenu
			  }
		) );
	}
</cfscript>