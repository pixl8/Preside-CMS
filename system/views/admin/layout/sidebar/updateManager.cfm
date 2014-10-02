<cfscript>
	if ( hasCmsPermission( "updateManager.manage" ) ) {
		WriteOutput( renderView(
			  view = "/admin/layout/sidebar/_menuItem"
			, args = {
				  active  = ListLast( event.getCurrentHandler(), ".") eq "updateManager"
				, link    = event.buildAdminLink( linkTo="updateManager" )
				, gotoKey = "p"
				, icon    = "fa-cloud-download"
				, title   = translateResource( 'cms:updateManager' )
			  }
		) );
	}
</cfscript>
