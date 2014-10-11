<cfscript>
	if ( isFeatureEnabled( "datamanager" ) && hasCmsPermission( "datamanager.navigate" ) ) {
		WriteOutput( renderView(
			  view = "/admin/layout/sidebar/_menuItem"
			, args = {
				  active  = ListLast( event.getCurrentHandler(), ".") eq "datamanager"
				, link    = event.buildAdminLink( linkTo="datamanager" )
				, gotoKey = "d"
				, icon    = "fa-puzzle-piece"
				, title   = translateResource( 'cms:datamanager' )
			  }
		) );
	}
</cfscript>