<cfif isFeatureEnabled( "passwordPolicyManager" )>
	<cfoutput>
		<cfif hasCmsPermission( "passwordpolicymanager.manage" )>
			<li>
				<a href="#event.buildAdminLink( linkTo='passwordpolicymanager' )#">
					<i class="fa fa-fw fa-key"></i>
					#translateResource( 'cms:passwordpolicymanager.configmenu.title' )#
				</a>
			</li>
		</cfif>
	</cfoutput>
</cfif>