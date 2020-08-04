<cfif isFeatureEnabled( "dataexport" ) && hasCmsPermission( "savedExport.navigate" )>
	<cfoutput>
		<li>
			<a href="#event.buildAdminLink( objectName="saved_export" )#">
				<i class="fa fa-fw fa-download"></i>
				#translateResource( 'cms:savedexport' )#
			</a>
		</li>
	</cfoutput>
</cfif>