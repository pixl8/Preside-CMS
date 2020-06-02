<cfif hasCmsPermission( "taskmanager.navigate" )>
	<cfoutput>
		<li>
			<a href="#event.buildAdminLink( linkTo="taskmanager" )#">
				<i class="fa fa-fw fa-clock-o"></i>
				#translateResource( 'cms:taskmanager' )#
			</a>
		</li>
	</cfoutput>
</cfif>
