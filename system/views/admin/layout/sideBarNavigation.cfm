<cfscript>
	handler = event.getCurrentHandler();
</cfscript>


<cfoutput>
	<div class="sidebar" id="sidebar">
		<script type="text/javascript">
			try{ace.settings.check('sidebar' , 'fixed')}catch(e){}
		</script>

		<ul class="nav nav-list">

			<cfif hasPermission( "sitetree.navigate" )>
				<li<cfif listLast( handler, ".") eq "sitetree"> class="active"</cfif>>
					<a href="#event.buildAdminLink( linkTo="sitetree" )#" data-goto-key="s">
						<i class="fa fa-sitemap"></i>
						<span class="menu-text">#translateResource( 'cms:sitetree' )#</span>
					</a>
				</li>
			</cfif>

			<cfif hasPermission( "assetmanager.general.navigate" )>
				<li<cfif listLast( handler, ".") eq "assetmanager"> class="active"</cfif>>
					<a href="#event.buildAdminLink( linkTo="assetmanager" )#" data-goto-key="a">
						<i class="fa fa-picture-o"></i>
						<span class="menu-text">#translateResource( 'cms:assetManager' )#</span>
					</a>
				</li>
			</cfif>

			<cfif hasPermission( "datamanager.navigate" )>
				<li<cfif listLast( handler, ".") eq "datamanager"> class="active"</cfif>>
					<a href="#event.buildAdminLink( linkTo='datamanager' )#" data-goto-key="d">
						<i class="fa fa-puzzle-piece"></i>
						<span class="menu-text">#translateResource( "cms:datamanager" )#</span>
					</a>
				</li>
			</cfif>

			<cfif hasPermission( "usermanager.navigate" ) || hasPermission( "groupmanager.navigate" )>
				<li<cfif listLast( handler, ".") eq "usermanager"> class="active"</cfif>>
					<a class="dropdown-toggle" href="##">
						<i class="fa fa-group"></i>
						<span class="menu-text">#translateResource( "cms:usermanager" )#</span>
						<b class="arrow fa fa-angle-down"></b>
					</a>

					<ul class="submenu">
						<cfif hasPermission( "usermanager.navigate" )>
							<li>
								<a href="#event.buildAdminLink( linkTo='usermanager.users' )#">
									<i class="fa fa-angle-double-right"></i>
									#translateResource( "cms:usermanager.users" )#
								</a>
							</li>
						</cfif>
						<cfif hasPermission( "groupmanager.navigate" )>
							<li>
								<a href="#event.buildAdminLink( linkTo='usermanager.groups' )#">
									<i class="fa fa-angle-double-right"></i>
									#translateResource( "cms:usermanager.groups" )#
								</a>
							</li>
						</cfif>
					</ul>
				</li>
			</cfif>

			<cfif hasPermission( "websiteusermanager.navigate" ) || hasPermission( "groupmanager.navigate" )>
				<li<cfif listLast( handler, ".") eq "websiteusermanager"> class="active"</cfif>>
					<a class="dropdown-toggle" href="##">
						<span class="fa-stack">
						  <i class="fa fa-globe fa-stack-lg"></i>
						  <i class="fa fa-user fa-stack-1x"></i>
						</span>
						<span class="menu-text">#translateResource( "cms:websiteusermanager" )#</span>
						<b class="arrow fa fa-angle-down"></b>
					</a>

					<ul class="submenu">
						<cfif hasPermission( "websiteusermanager.navigate" )>
							<li>
								<a href="#event.buildAdminLink( linkTo='websiteusermanager' )#">
									<i class="fa fa-angle-double-right"></i>
									#translateResource( "cms:websiteUserManager.users" )#
								</a>
							</li>
						</cfif>
						<cfif hasPermission( "groupmanager.navigate" )>
							<li>
								<a href="#event.buildAdminLink( linkTo='websitebenefitsmanager' )#">
									<i class="fa fa-angle-double-right"></i>
									#translateResource( "cms:websiteUserManager.benefits" )#
								</a>
							</li>
						</cfif>
					</ul>
				</li>
			</cfif>

			<cfif hasPermission( "systemConfiguration.manage" )>
				<li<cfif listLast( handler, ".") eq "sysconfig"> class="active"</cfif>>
					<a class="dropdown-toggle" href="##">
						<i class="fa fa-cogs"></i>
						<span class="menu-text">#translateResource( "cms:sysconfig" )#</span>
						<b class="arrow fa fa-angle-down"></b>
					</a>

					<ul class="submenu">
						#renderViewlet( event="admin.sysconfig.categoryMenu" )#
					</ul>
				</li>
			</cfif>

			<cfif hasPermission( "updateManager.manage" )>
				<li<cfif listLast( handler, ".") eq "updateManager"> class="active"</cfif>>
					<a href="#event.buildAdminLink( linkTo='updateManager' )#">
						<i class="fa fa-cloud-download"></i>
						<span class="menu-text">#translateResource( "cms:updateManager" )#</span>
					</a>
				</li>
			</cfif>
		</ul>


		<div class="sidebar-collapse" id="sidebar-collapse">
			<i class="fa fa-angle-double-left" data-icon1="fa fa-angle-double-left" data-icon2="fa fa-angle-double-right"></i>
		</div>

		<script type="text/javascript">
			try{ace.settings.check('sidebar' , 'collapsed')}catch(e){}
		</script>
	</div>
</cfoutput>