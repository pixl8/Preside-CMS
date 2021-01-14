<cfif isFeatureEnabled( "rulesEngine" ) && hasCmsPermission( "rulesEngine.navigate" )>
	<cfoutput>
		<li>
			<a href="#event.buildAdminLink( objectName='rules_engine_condition' )#">
				<i class="fa fa-fw fa-#translateResource( "cms:rulesEngine.iconClass" )#"></i>
				#translateResource( "cms:rulesEngine.navigation.link" )#
			</a>
		</li>
	</cfoutput>
</cfif>