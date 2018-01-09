<cfscript>
	objectGroups       = event.getValue( name="objectGroups", defaultValue=[], private=true );

	// display logic to split groups into three equalish columns
	groupsColRemainder = objectGroups.len() mod 3;
	groupsPerCol       = Ceiling( objectGroups.len() / 3 );
	groupColCounts     = [ { from=1, to=groupsPerCol } ];

	if ( groupsColRemainder ) {
		if ( objectGroups.len() > 1 ) {
			if ( groupsColRemainder == 1 ) {
				groupColCounts.append( { from=groupColCounts[1].to+1, to=groupColCounts[1].to + groupsPerCol - 1 } );
			} else {
				groupColCounts.append( { from=groupColCounts[1].to+1, to=groupColCounts[1].to + groupsPerCol } );
			}
			if ( objectGroups.len() > 2 ) {
				groupColCounts.append( { from=groupColCounts[2].to+1, to=objectGroups.len() } );
			}
		}
	} else {
		groupColCounts.append( { from=groupColCounts[1].to+1, to=groupColCounts[1].to + groupsPerCol + 1 } );
		groupColCounts.append( { from=groupColCounts[2].to+1, to=groupColCounts[2].to + groupsPerCol + 1 } );
	}
	// end display logic to split groups into three equalish columns

	prc.pageIcon  = "puzzle-piece";
	prc.pageTitle = translateResource( "cms:datamanager" );
</cfscript>

<cfoutput>
	<cfif not ArrayLen( objectGroups )>
		<p>#translateResource( "cms:datamanager.nonetodisplay" )#</p>
	<cfelse>
		<div class="row">
			<cfloop from="1" to="#groupColCounts.len()#" index="col">
				<div class="col-sm-4">
					<cfloop from="#groupColCounts[ col ].from#" to="#groupColCounts[ col ].to#" index="listIndex">
						<cfset group = objectGroups[ listIndex ] />
						<div class="well">
							<h4 class="small lighter green"><i class="fa #group.icon#"></i> &nbsp;#group.title#</h4>
							<p>#group.description#</p>

							<ul class="list-unstyled" data-nav-list="#listIndex#" data-nav-list-child-selector="li a">
								<cfloop array="#group.objects#" index="obj">
									<li>
										<i class="fa fa-fw #obj.iconClass#"></i>&nbsp;
										<a href="#event.buildAdminLink( objectName=obj.id, operation="listing" )#">
											#obj.title#
										</a>
									</li>
								</cfloop>
							</ul>
						</div>
					</cfloop>
				</div>
			</cfloop>
		</div>
	</cfif>
</cfoutput>

