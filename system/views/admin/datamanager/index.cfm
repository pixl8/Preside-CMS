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
		groupColCounts.append( { from=groupColCounts[1].to+1, to=groupColCounts[1].to + groupsPerCol } );
		groupColCounts.append( { from=groupColCounts[2].to+1, to=groupColCounts[2].to + groupsPerCol } );
	}
	// end display logic to split groups into three equalish columns
</cfscript>

<cfoutput>
	<cfif not ArrayLen( objectGroups )>
		<p>#translateResource( "cms:datamanager.nonetodisplay" )#</p>
	<cfelse>
		<div class="info-bar">
			<label class="block clearfix" for="datamanager-search-box">
				<span class="block input-icon">
					<input type              = "text"
					       id                = "datamanager-search-box"
					       class             = "search-box form-control"
					       placeholder       = "#translateResource( 'cms:datamanager.global.search.placeholder' )#"
					       name              = "q"
					       autocomplete      = "off"
					       data-global-key   = "s">

					<i class="fa fa-search"></i>
				</span>
			</label>
		</div>

		<div class="row">
			<cfloop from="1" to="#groupColCounts.len()#" index="col">
				<div class="col-sm-4 datamanager-group-column">
					<cfloop from="#groupColCounts[ col ].from#" to="#groupColCounts[ col ].to#" index="listIndex">
						<cfset group = objectGroups[ listIndex ] />
						<div class="well datamanager-group">
							<h4 class="small lighter green"><i class="fa #group.icon#"></i> &nbsp;<span class="datamanager-group-title">#group.title#</span></h4>
							<p>#group.description#</p>

							<ul class="list-unstyled" data-nav-list="#listIndex#" data-nav-list-child-selector="li a">
								<cfloop array="#group.objects#" index="obj">
									<li class="datamanager-object">
										<i class="fa fa-fw #obj.iconClass#"></i>&nbsp;
										<a href="#event.buildAdminLink( objectName=obj.id, operation="listing" )#" class="datamanager-object-title">
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

