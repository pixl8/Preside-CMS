<cfif hasCmsPermission( "assetmanager.general.navigate" )>
	<cfoutput>
		<li<cfif listLast( event.getCurrentHandler(), ".") eq "assetmanager"> class="active"</cfif>>
			<a href="#event.buildAdminLink( linkTo="assetmanager" )#" data-goto-key="a">
				<i class="fa fa-picture-o"></i>
				<span class="menu-text">#translateResource( 'cms:assetManager' )#</span>
			</a>
		</li>
	</cfoutput>
</cfif>