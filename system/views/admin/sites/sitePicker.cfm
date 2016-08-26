<cfscript>
	param name="args.sites"       type="array";
	param name="args.currentSite" type="struct";

	hasManagementPerms = hasCmsPermission( "sites.manage" );
	showSiteNavigation = isFeatureEnabled( "sites" ) && ( hasManagementPerms || args.sites.len() );
</cfscript>

<cfoutput>
	<cfif showSiteNavigation>
		<div class="navbar-header pull-left" role="navigation">
			<ul class="nav ace-nav">
				<li class="site-picker">
					<a data-toggle="dropdown" href="##" class="dropdown-toggle">
						<span class="current-site">
							<i class="fa fa-globe fa-lg"></i>
							#args.currentSite.name#
						</span>

						<i class="fa fa-caret-down"></i>
					</a>

					<ul class="site-menu dropdown-menu dropdown-yellow dropdown-caret dropdown-close">
						<cfloop array="#args.sites#" index="i" item="site">
							<li>
								<a href="#event.buildAdminLink( linkTo='sites.setActiveSite', queryString='id=#site.id#' )#">
									<i class="fa fa-globe"></i>
									#site.name#
								</a>
							</li>
						</cfloop>

						<cfif hasManagementPerms>
							<cfif ArrayLen( args.sites )>
								<li class="divider"></li>
							</cfif>
							<li>
								<a href="#event.buildAdminLink( linkTo="sites.manage" )#">
									<i class="fa fa-pencil-square-o"></i>
									#translateResource( "cms:sitenav.managesites" )#
								</a>
							</li>
						</cfif>
					</ul>
				</li>
			</ul>
		</div>
	</cfif>
</cfoutput>