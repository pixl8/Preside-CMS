<cfscript>
	clickStats = args.clickStats ?: [];
</cfscript>
<cfoutput>
	<div class="widget-box">
		<div class="widget-header">
			<h4 class="widget-title lighter smaller">
				<i class="fa fa-fw fa-mouse-pointer"></i>
				#translateResource( "cms:emailcenter.stats.clickstats.box.title" )#
			</h4>
		</div>

		<div class="widget-body">
			<div class="widget-main padding-20">
				<cfif clickStats.len()>
					<div class="table-responsive">
	 					<table class="table no-top-border">
	 						<thead>
	 							<tr>
	 								<th>#translateResource( "cms:emailcenter.stats.clickstats.box.link.header"  )#</th>
	 								<th>#translateResource( "cms:emailcenter.stats.clickstats.box.count.header" )#</th>
	 							</tr>
	 						</thead>
	 						<tbody>
								<cfloop array="#clickStats#" item="clickStat" index="i">
									<tr>
										<td>
											<a href="#clickStat.link#" title="#clickStat.link#">
												#abbreviate( clickStat.link, 75 )#
											</a>
										</td>
										<td>#NumberFormat( clickStat.clickCount )#</td>
									</tr>
								</cfloop>
							</tbody>
						</table>
					</div>
				<cfelse>
					<p class="text-center light-grey"><em>#translateResource( "cms:emailcenter.stats.clickstats.box.no.stats" )#</em></p>
				</cfif>
			</div>
		</div>
	</div>
</cfoutput>