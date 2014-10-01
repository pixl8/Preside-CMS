<cfif hasCmsPermission( "usermanager.navigate" ) || hasCmsPermission( "groupmanager.navigate" )>
	<cfoutput>
		<li<cfif listLast( event.getCurrentHandler(), ".") eq "usermanager"> class="active"</cfif>>
			<a class="dropdown-toggle" href="##">
				<i class="fa fa-group"></i>
				<span class="menu-text">#translateResource( "cms:usermanager" )#</span>
				<b class="arrow fa fa-angle-down"></b>
			</a>

			<ul class="submenu">
				<cfif hasCmsPermission( "usermanager.navigate" )>
					<li>
						<a href="#event.buildAdminLink( linkTo='usermanager.users' )#">
							<i class="fa fa-angle-double-right"></i>
							#translateResource( "cms:usermanager.users" )#
						</a>
					</li>
				</cfif>
				<cfif hasCmsPermission( "groupmanager.navigate" )>
					<li>
						<a href="#event.buildAdminLink( linkTo='usermanager.groups' )#">
							<i class="fa fa-angle-double-right"></i>
							#translateResource( "cms:usermanager.groups" )#
						</a>
					</li>
				</cfif>
			</ul>
		</li>
	</cfoutput>
</cfif>