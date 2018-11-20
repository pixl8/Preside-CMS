<cfscript>
	clickStats = args.clickStats ?: [];
	event.include( "/css/admin/specific/emailcenter/clickstatstable/" );
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
	 					<table class="table no-top-border click-stats-table">
	 						<thead>
	 							<tr>
	 								<th>#translateResource( "cms:emailcenter.stats.clickstats.box.link.header"  )#</th>
	 								<th class="count-col">#translateResource( "cms:emailcenter.stats.clickstats.box.count.header" )#</th>
	 							</tr>
	 						</thead>
	 						<tbody>
								<cfloop array="#clickStats#" item="clickStat" index="i">
									<tr>
										<td>
											#renderEmailTrackingLink( clickStat.link, clickStat.title, clickStat.body )#
										</td>
										<td class="count-col">#NumberFormat( clickStat.clickCount )#</td>
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