<cfif ( isFeatureEnabled( "auditTrail" ) && hasCmsPermission( "auditTrail.navigate" ) )>
	<cfoutput>
		<li>
			<a href="#event.buildAdminLink( linkTo="auditTrail" )#">
				<i class="fa fa-fw fa-history"></i>
				#translateResource( 'cms:auditTrail' )#
			</a>
		</li>
	</cfoutput>
</cfif>