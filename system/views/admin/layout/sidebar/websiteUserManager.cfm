<cfif hasCmsPermission( "websiteUserManager.navigate" ) || hasCmsPermission( "websiteBenefitsManager.navigate" )>
	<cfoutput>
		<li<cfif listLast( event.getCurrentHandler(), ".") eq "websiteUserManager"> class="active"</cfif>>
			<a class="dropdown-toggle" href="##">
				<span class="fa-stack">
				  <i class="fa fa-globe fa-stack-lg"></i>
				  <i class="fa fa-user fa-stack-1x"></i>
				</span>
				<span class="menu-text">#translateResource( "cms:websiteUserManager" )#</span>
				<b class="arrow fa fa-angle-down"></b>
			</a>

			<ul class="submenu">
				<cfif hasCmsPermission( "websiteUserManager.navigate" )>
					<li>
						<a href="#event.buildAdminLink( linkTo='websiteUserManager' )#">
							<i class="fa fa-angle-double-right"></i>
							#translateResource( "cms:websiteUserManager.users" )#
						</a>
					</li>
				</cfif>
				<cfif hasCmsPermission( "websiteBenefitsManager.navigate" )>
					<li>
						<a href="#event.buildAdminLink( linkTo='websitebenefitsmanager' )#">
							<i class="fa fa-angle-double-right"></i>
							#translateResource( "cms:websiteUserManager.benefits" )#
						</a>
					</li>
				</cfif>
			</ul>
		</li>
	</cfoutput>
</cfif>