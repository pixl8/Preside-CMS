<cfif isFeatureEnabled( "cmsUserManager" )>
	<cfoutput>
		<cfif hasCmsPermission( "usermanager.navigate" )>
			<li>
				<a href="#event.buildAdminLink( linkTo="usermanager.users" )#">
					<i class="fa fa-fw fa-user"></i>
					#translateResource( 'cms:usermanager.users' )#
				</a>
			</li>
		</cfif>

		<cfif hasCmsPermission( "groupmanager.navigate" )>
			<li>
				<a href="#event.buildAdminLink( linkTo="usermanager.groups" )#">
					<i class="fa fa-fw fa-group"></i>
					#translateResource( 'cms:usermanager.groups' )#
				</a>
			</li>
		</cfif>
	</cfoutput>
</cfif>