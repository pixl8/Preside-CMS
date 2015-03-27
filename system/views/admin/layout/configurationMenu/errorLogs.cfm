<cfif ( isFeatureEnabled( "errorlogs" ) && hasCmsPermission( "errorlogs.navigate" ) )>
	<cfoutput>
		<li>
			<a href="#event.buildAdminLink( linkTo="errorlogs" )#">
				<i class="fa fa-fw fa-exclamation-circle"></i>
				#translateResource( 'cms:errorlogs' )#
			</a>
		</li>
	</cfoutput>
</cfif>