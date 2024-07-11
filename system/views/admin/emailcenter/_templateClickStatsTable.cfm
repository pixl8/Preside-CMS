<!---@feature admin and emailCenter--->
<cfscript>
	clickStats = args.clickStats ?: {};
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
								<cfloop item="currentItem" collection="#clickStats#" index="currentIndex">
									<cfset itemSlug=slugify( currentIndex ) />
									<tr>
										<td>
											<a href="javascript: void(0);" data-toggle="collapse" data-target=".click-stat-#itemSlug#">
												<i class="fa fa-plus"></i>
												#currentIndex#
											</a>
										</td>
										<td class="count-col">
											#currentItem.totalCount#
										</td>
									</tr>
									<cfloop array="#currentItem.links#" item="clickStat" index="i">
										<tr class="collapse click-stat-#itemSlug#">
											<td>
												&nbsp;&nbsp;
												<a href="#clickStat.link#" class="email-stats-link">
													<i class="fa fa-link"></i>
													<cfif isEmptyString( clickStat.title )>
														#clickStat.link#
													<cfelse>
														#clickStat.title#
													</cfif>
												</a>
											</td>
											<td width="200">
												#NumberFormat( clickStat.clickCount )#
											</td>
										</tr>
									</cfloop>
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