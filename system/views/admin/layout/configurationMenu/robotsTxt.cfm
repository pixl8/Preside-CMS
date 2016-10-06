<cfif hasCmsPermission( "robotsTxt.manage" )>
	<cfoutput>
		<li>
			<a href="#event.buildAdminLink( linkTo="robotsTxt" )#">
				<i class="fa fa-fw fa-reddit-alien"></i>
				#translateResource( 'cms:robotsTxt.menu.title' )#
			</a>
		</li>
	</cfoutput>
</cfif>