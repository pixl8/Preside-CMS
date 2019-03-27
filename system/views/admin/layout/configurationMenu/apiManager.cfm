<cfif isFeatureEnabled( "apiManager" ) && hasCmsPermission( "apiManager.navigate" )>
	<cfoutput>
		<li>
			<a href="#event.buildAdminLink( linkTo="apiManager" )#">
				<i class="fa fa-fw fa-code"></i>
				#translateResource( 'cms:apiManager' )#
			</a>
		</li>
	</cfoutput>
</cfif>
