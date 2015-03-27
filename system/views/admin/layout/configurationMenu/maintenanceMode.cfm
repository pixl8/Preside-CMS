<cfif hasCmsPermission( "maintenanceMode.configure" )>
	<cfoutput>
		<li>
			<a href="#event.buildAdminLink( linkTo="maintenanceMode" )#">
				<i class="fa fa-fw fa-medkit"></i>
				#translateResource( 'cms:maintenanceMode' )#
			</a>
		</li>
	</cfoutput>
</cfif>