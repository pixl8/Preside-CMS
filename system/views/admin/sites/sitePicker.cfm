<cfparam name="args.sites"       type="array" />
<cfparam name="args.currentSite" type="struct" />

<cfoutput>
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

				<ul class="site-menu pull-left dropdown-menu dropdown-yellow dropdown-caret dropdown-close">
					<cfif ArrayLen( args.sites )>
						<cfloop array="#args.sites#" index="i" item="site">
							<li>
								<a href="#event.buildAdminLink( linkTo='sites.setActiveSite', queryString='id=#site.id#' )#">
									<i class="fa fa-globe"></i>
									#site.name#
								</a>
							</li>
						</cfloop>
						<li class="divider"></li>
					</cfif>

					<li>
						<a href="##">
							<i class="fa fa-pencil-square-o"></i>
							#translateResource( "cms:sitenav.managesites" )#
						</a>
					</li>
				</ul>
			</li>
		</ul>
	</div>
</cfoutput>