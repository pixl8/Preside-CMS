<cfif hasCmsPermission( "updateManager.manage" )>
	<cfoutput>
		<li<cfif listLast( event.getCurrentHandler(), ".") eq "updateManager"> class="active"</cfif>>
			<a href="#event.buildAdminLink( linkTo='updateManager' )#">
				<i class="fa fa-cloud-download"></i>
				<span class="menu-text">#translateResource( "cms:updateManager" )#</span>
			</a>
		</li>
	</cfoutput>
</cfif>