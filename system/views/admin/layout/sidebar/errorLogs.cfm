<cfscript>
	if ( isFeatureEnabled( "errorlogs" ) && hasCmsPermission( "errorlogs.navigate" ) ) {
		WriteOutput( renderView(
			  view = "/admin/layout/sidebar/_menuItem"
			, args = {
				  active  = ListLast( event.getCurrentHandler(), ".") eq "errorlogs"
				, link    = event.buildAdminLink( linkTo="errorlogs" )
				, icon    = "fa-exclamation-circle"
				, title   = translateResource( 'cms:errorlogs' )
			  }
		) );
	}
</cfscript>