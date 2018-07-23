<cfscript>
	templateId = rc.id ?: "";
	showClicks = IsTrue( prc.showClicks ?: "" );

	if ( showClicks ) {
		clickStats = prc.clickStats ?: [];
	}
</cfscript>
<cfoutput>
	<cfsavecontent variable="body">
		<div class="clearfix">
			#renderViewlet(
				  event = "admin.emailcenter.templateStatsSummary"
				, args  = { templateId=templateId }
			)#
		</div>

		<br>

		<cfif showClicks>
			<div class="row">
				<div class="col-md-8 col-lg-7">
		</cfif>

		<div class="widget-box">
			<div class="widget-header">
				<h4 class="widget-title lighter smaller">
					<i class="fa fa-fw fa-line-chart"></i>
					#translateResource( "cms:emailcenter.stats.history.box.title" )#
				</h4>
			</div>

			<div class="widget-body">
				<div class="widget-main padding-20">
					TODO
				</div>
			</div>
		</div>

		<cfif showClicks>
				</div>
				<div class="col-md-4 col-lg-5">
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
					 					<table class="table">
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
															<a href="#clickStat.link#">#clickStat.link#</a>
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
				</div>
			</div>
		</cfif>
	</cfsavecontent>

	#renderViewlet( event="admin.emailcenter.customtemplates._customTemplateTabs", args={ body=body, tab="stats" } )#
</cfoutput>