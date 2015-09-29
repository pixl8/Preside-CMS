<cfif hasCmsPermission( "urlRedirects.navigate" )>
	<cfoutput>
		<li>
			<a href="#event.buildAdminLink( linkTo='urlRedirects' )#">
				<i class="fa fa-fw fa-code-fork"></i>
				#translateResource( "cms:urlRedirects.navigation.link" )#
			</a>
		</li>
	</cfoutput>
</cfif>