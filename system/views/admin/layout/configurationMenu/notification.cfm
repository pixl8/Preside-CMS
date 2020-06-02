<cfoutput>
	<cfif hasCmsPermission( "notifications.configure" )>
		<li>
			<a href="#event.buildAdminLink( linkTo="notifications.configure" )#">
				<i class="fa fa-fw fa-bell"></i>
				#translateResource( uri="cms:notifications.system.menu.title" )#
			</a>
		</li>
	</cfif>
</cfoutput>