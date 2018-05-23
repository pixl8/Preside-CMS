<cfscript>
	if ( isFeatureEnabled( "datamanager" ) && hasCmsPermission( "datamanager.navigate" ) ) {
		WriteOutput( renderView(
			  view = "/admin/layout/sidebar/_menuItem"
			, args = {
				  active  = ListLast( event.getCurrentHandler(), ".") eq "datamanager" && ( IsTrue( prc.objectInDatamanagerUi ?: "" ) || !Len( Trim( prc.objectName ) ) )
				, link    = event.buildAdminLink( linkTo="datamanager" )
				, gotoKey = "d"
				, icon    = "fa-database"
				, title   = translateResource( 'cms:datamanager' )
			  }
		) );
	}
</cfscript>