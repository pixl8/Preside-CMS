<cfif ( isFeatureEnabled( "emailLogs" ) && hasCmsPermission( "emailLogs.navigate" ) )>
	<cfoutput>
		<li>
			<a href="#event.buildAdminLink( linkTo="emailLogs" )#">
				<i class="fa fa-fw fa-envelope"></i>
				#translateResource( 'cms:emailLogs' )#
			</a>
		</li>
	</cfoutput>
</cfif>