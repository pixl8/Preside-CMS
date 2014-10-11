<cfscript>
	if ( isFeatureEnabled( "assetManager" ) && hasCmsPermission( "assetmanager.general.navigate" ) ) {
		WriteOutput( renderView(
			  view = "/admin/layout/sidebar/_menuItem"
			, args = {
				  active  = ListLast( event.getCurrentHandler(), ".") eq "assetmanager"
				, link    = event.buildAdminLink( linkTo="assetmanager" )
				, gotoKey = "a"
				, icon    = "fa-picture-o"
				, title   = translateResource( 'cms:assetManager' )
			  }
		) );
	}
</cfscript>