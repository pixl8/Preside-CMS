<cfscript>
	objectGroups = event.getValue( name="objectGroups", defaultValue=[], private=true );

	prc.pageIcon  = "puzzle-piece";
	prc.pageTitle = translateResource( "cms:datamanager" );
</cfscript>

<cfoutput>
	<cfif not ArrayLen( objectGroups )>
		<p>#translateResource( "cms:datamanager.nonetodisplay" )#</p>
	<cfelse>
		<div class="row">
			<cfloop array="#objectGroups#" index="listIndex" item="group">
				<div class="col-sm-4">
					<div class="well">
						<h4 class="small lighter green"><i class="fa #group.icon#"></i> &nbsp;#group.title#</h4>
						<p>#group.description#</p>

						<ul class="list-unstyled" data-nav-list="#listIndex#" data-nav-list-child-selector="li a">
							<cfloop array="#group.objects#" index="obj">
								<li>
									<i class="fa fa-puzzle-piece"></i>
									<a href="#event.buildAdminLink( linkTo="datamanager.object", querystring="id=#obj.id#" )#">
										#obj.title#
									</a>
								</li>
							</cfloop>
						</ul>
					</div>
				</div>
			</cfloop>
		</div>
	</cfif>
</cfoutput>

