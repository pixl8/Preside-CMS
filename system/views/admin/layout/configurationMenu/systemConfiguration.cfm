<cfif ( isFeatureEnabled( "systemConfiguration" ) && hasCmsPermission( "systemConfiguration.manage" ) )>
	<cfoutput>
		<li>
			<a href="#event.buildAdminLink( linkTo="sysconfig" )#">
				<i class="fa fa-fw fa-cogs"></i>
				#translateResource( 'cms:sysconfig.menu.title' )#
			</a>
		</li>
	</cfoutput>
</cfif>