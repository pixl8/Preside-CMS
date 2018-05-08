<cfoutput>
	<li>
		<a href="#event.buildAdminLink( linkTo="notifications.preferences" )#">
			<i class="fa fa-fw fa-cog"></i>
			#translateResource( uri="cms:notifications.preferences.title" )#
		</a>
	</li>

	<cfif hasCmsPermission( "notifications.configure" )>
		<li>
			<a href="#event.buildAdminLink( linkTo="notifications.configure" )#">
				<i class="fa fa-fw fa-cogs"></i>
				#translateResource( uri="cms:notifications.configure.title" )#
			</a>
		</li>
	</cfif>
</cfoutput>