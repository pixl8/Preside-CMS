<cfscript>
	if ( isFeatureEnabled( "sitetree" ) && hasCmsPermission( "sitetree.navigate" ) ) {
		WriteOutput( renderView(
			  view = "/admin/layout/sidebar/_menuItem"
			, args = {
				  active  = ListLast( event.getCurrentHandler(), ".") eq "sitetree"
				, link    = event.buildAdminLink( linkTo="sitetree" )
				, gotoKey = "s"
				, icon    = "fa-sitemap"
				, title   = translateResource( 'cms:sitetree' )
			  }
		) );
	}
</cfscript>