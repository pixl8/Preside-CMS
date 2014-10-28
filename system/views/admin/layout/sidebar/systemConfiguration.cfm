<cfscript>
	if ( isFeatureEnabled( "systemConfiguration" ) && hasCmsPermission( "systemConfiguration.manage" ) ) {
		WriteOutput( renderView(
			  view = "/admin/layout/sidebar/_menuItem"
			, args = {
				  active  = ListLast( event.getCurrentHandler(), ".") eq "sysconfig"
				, icon    = "fa-cogs"
				, title   = translateResource( 'cms:sysconfig' )
				, submenu = renderViewlet( event="admin.sysconfig.categoryMenu" )
			  }
		) );
	}
</cfscript>