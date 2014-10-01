<cfif hasCmsPermission( "systemConfiguration.manage" )>
	<cfoutput>
		<li<cfif listLast( event.getCurrentHandler(), ".") eq "sysconfig"> class="active"</cfif>>
			<a class="dropdown-toggle" href="##">
				<i class="fa fa-cogs"></i>
				<span class="menu-text">#translateResource( "cms:sysconfig" )#</span>
				<b class="arrow fa fa-angle-down"></b>
			</a>

			<ul class="submenu">
				#renderViewlet( event="admin.sysconfig.categoryMenu" )#
			</ul>
		</li>
	</cfoutput>
</cfif>