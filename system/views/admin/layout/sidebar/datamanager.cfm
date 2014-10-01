<cfif hasCmsPermission( "datamanager.navigate" )>
	<cfoutput>
		<li<cfif listLast( event.getCurrentHandler(), ".") eq "datamanager"> class="active"</cfif>>
			<a href="#event.buildAdminLink( linkTo='datamanager' )#" data-goto-key="d">
				<i class="fa fa-puzzle-piece"></i>
				<span class="menu-text">#translateResource( "cms:datamanager" )#</span>
			</a>
		</li>
	</cfoutput>
</cfif>