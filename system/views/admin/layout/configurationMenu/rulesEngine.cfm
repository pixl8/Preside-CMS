<cfif isFeatureEnabled( "rulesEngine" ) && hasCmsPermission( "rulesEngine.navigate" )>
	<cfoutput>
		<li>
			<a href="#event.buildAdminLink( linkTo='rulesEngine' )#">
				<i class="fa fa-fw fa-#translateResource( "cms:rulesEngine.iconClass" )#"></i>
				#translateResource( "cms:rulesEngine.navigation.link" )#
			</a>
		</li>
	</cfoutput>
</cfif>