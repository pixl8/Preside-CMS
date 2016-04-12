<cfif ( isFeatureEnabled( "updateManager" ) && hasCmsPermission( "updateManager.manage" ) )>
	<cfoutput>
		<li>
			<a href="#event.buildAdminLink( linkTo="updateManager" )#">
				<i class="fa fa-fw fa-cloud-download"></i>
				#translateResource( 'cms:updateManager.menu.title' )#
			</a>
		</li>
	</cfoutput>
</cfif>
