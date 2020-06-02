<cfif ( isFeatureEnabled( "systemInformation" ) && hasCmsPermission( "systemInformation.navigate" ) )>
	<cfoutput>		
		<li>
			<a href="#event.buildAdminLink( linkTo="systemInformation" )#">
				<i class="fa fa-fw fa-info-circle"></i>
				#translateResource( 'cms:systemInformation.menu.title' )#
			</a>
		</li>
	</cfoutput>
</cfif>
