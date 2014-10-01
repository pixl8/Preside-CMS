<cfif hasCmsPermission( "sitetree.navigate" )>
	<cfoutput>
		<li<cfif listLast( event.getCurrentHandler(), ".") eq "sitetree"> class="active"</cfif>>
			<a href="#event.buildAdminLink( linkTo="sitetree" )#" data-goto-key="s">
				<i class="fa fa-sitemap"></i>
				<span class="menu-text">#translateResource( 'cms:sitetree' )#</span>
			</a>
		</li>
	</cfoutput>
</cfif>