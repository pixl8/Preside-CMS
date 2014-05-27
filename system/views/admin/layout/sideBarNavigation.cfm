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
		</ul>


		<div class="sidebar-collapse" id="sidebar-collapse">
			<i class="fa fa-angle-double-left" data-icon1="fa fa-angle-double-left" data-icon2="fa fa-angle-double-right"></i>
		</div>

		<script type="text/javascript">
			try{ace.settings.check('sidebar' , 'collapsed')}catch(e){}
		</script>
	</div>
</cfoutput>