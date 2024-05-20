<!---@feature admin and emailCenter--->
<cfscript>
	stats                = args.stats ?: {};
	clickTrackingEnabled = stats.uniqueClickCount || isTrue( prc.record.track_clicks );
	dateFields = {
		  bounces      = "hard_bounced_date"
		, unsubscribes = "unsubscribed_date"
		, complaints   = "marked_as_spam_date"
	};
	botsDetected = Val( stats.botOpenCount ) || Val( stats.botClickCount );
</cfscript>

<cfoutput>
	<cfif botsDetected>
		<p class="alert alert-warning">
			<i class="fa fa-fw fa-info-circle"></i>
			#translateResource( uri="cms:emailcenter.stats.bots.detected", data=[ LsNumberFormat( stats.botOpenCount ), LsNumberFormat( stats.botClickCount ) ] )#
		</p>
	</cfif>
	<div class="row">
		<div class="col-md-7">
			<div class="row">
				<div class="col-md-4">
					<div class="panel">
						<div class="panel-heading">
							<h4 class="panel-title grey">
								<i class="fa fa-fw fa-paper-plane"></i>
								#translateResource( "cms:emailcenter.stats.panel.delivery" )#
							</h4>
						</div>
						<div class="panel-body">
							<p class="big-stat">
								#translateResource( uri="cms:emailcenter.stats.panel.delivery.sendcount", data=[ LsNumberFormat( stats.sendCount ) ] )#<br>
								#translateResource( uri="cms:emailcenter.stats.panel.delivery.deliveryrate", data=[ LsNumberFormat( stats.deliveryCount ), LsNumberFormat( stats.deliveryRate, "0.00" ) ] )#<br>
								#translateResource( uri="cms:emailcenter.stats.panel.delivery.bouncerate", data=[ LsNumberFormat( stats.bounceCount ), LsNumberFormat( stats.bounceRate, "0.00"   ) ] )#
							</p>
						</div>
					</div>
				</div>
				<div class="col-md-4">
					<div class="panel">
						<div class="panel-heading">
							<h4 class="panel-title grey">
								<i class="fa fa-fw fa-user"></i>
								#translateResource( "cms:emailcenter.stats.panel.engagement" )#
							</h4>
						</div>
						<div class="panel-body">
							<p class="big-stat">
								#translateResource( uri="cms:emailcenter.stats.panel.engagement.openrate"   , data=[ LsNumberFormat( stats.uniqueOpenCount ), LsNumberFormat( stats.openRate        , "0.00" ), LsNumberFormat( stats.totalOpenCount ) ] )#<br>
								<cfif clickTrackingEnabled >
									#translateResource( uri="cms:emailcenter.stats.panel.engagement.ctr"        , data=[ LsNumberFormat( stats.uniqueClickCount ), LsNumberFormat( stats.clickThroughRate, "0.00" ), LsNumberFormat( stats.totalClickCount ) ] )#<br>
									#translateResource( uri="cms:emailcenter.stats.panel.engagement.ctor"       , data=[ LsNumberFormat( stats.clickToOpenRate, "0.00" ) ] )#
								<cfelse>
									#translateResource( uri="cms:emailcenter.stats.panel.engagement.clicks.not.tracked" )#<br>
									&nbsp;<!--- hack --->
								</cfif>
							</p>
						</div>
					</div>
				</div>
				<div class="col-md-4">
					<div class="panel">
						<div class="panel-heading">
							<h4 class="panel-title grey">
								<i class="fa fa-fw fa-sign-out"></i>
								#translateResource( "cms:emailcenter.stats.panel.negativeengagement" )#
							</h4>
						</div>
						<div class="panel-body">
							<p class="big-stat">
								#translateResource( uri="cms:emailcenter.stats.panel.negativeengagement.unsubscriberate", data=[ LsNumberFormat( stats.unsubscribeCount ), LsNumberFormat( stats.unsubscribeRate, "0.00" ) ] )#<br>
								#translateResource( uri="cms:emailcenter.stats.panel.negativeengagement.complaintrate"  , data=[ LsNumberFormat( stats.complaintCount ), LsNumberFormat( stats.complaintRate  , "0.00" ) ] )#<br>
								&nbsp;<!--- hack --->
							</p>
						</div>
					</div>
				</div>
			</div>
			<div class="row">
				<div class="col-md-12">
					<div class="panel">
						<div class="panel-heading">
							<h4 class="panel-title grey">
								<i class="fa fa-fw fa-user"></i>
								#translateResource( "cms:emailcenter.stats.panel.engagementovertime" )#
							</h4>
						</div>
						<div class="panel-body">
							#renderViewlet( event="admin.emailcenter.templateStatsFilter", args={
								  templateId = args.templateId
								, containerClass  = "alert alert-info"
							} )#
							#renderViewlet( event="admin.emailcenter.templateInteractionStatsChart", args={
								  templateId = args.templateId
								, showPanel  = false
								, stats      = [ "opened", "clicks", "unsubscribes", "complaints" ]
							} )#
						</div>
					</div>

					<cfif clickTrackingEnabled >
						<div class="panel">
							<div class="panel-heading">
								<h4 class="panel-title grey">
									<i class="fa fa-fw fa-user"></i>
									#translateResource( "cms:emailcenter.stats.panel.mostactive" )#
								</h4>
							</div>
							<div class="panel-body">
								#renderView( view="/admin/datamanager/_objectDataTable", args={
									  objectName        = "email_template_send_log"
									, useMultiActions   = false
									, datasourceUrl     = event.buildAdminLink( linkTo="emailCenter.getFilteredRecipientsForStatsTables", queryString="id=#args.templateId#&statType=mostActive" )
									, gridFields        = [ args.recipientStatField ?: "recipient", "open_count", "click_count" ]
									, draftsEnabled     = false
									, allowSearch       = false
									, allowFilter       = false
									, compact           = true
									, defaultPageLength = 5
								} )#
							</div>
						</div>
					</cfif>
				</div>
			</div>
		</div>
		<div class="col-md-5">
			<cfif stats.hasClicks>
				<div class="panel">
					<div class="panel-heading">
						<h4 class="panel-title grey">
							<i class="fa fa-fw fa-mouse-pointer"></i>
							#translateResource( "cms:emailcenter.stats.panel.clickreport" )#
						</h4>
					</div>
					<div class="panel-body">
						<div class="table-responsive">
							<table class="table table-striped static-data-table" data-disable-search="true" data-disable-sort="true" data-default-page-length="5">
								<thead>
									<tr>
										<th>#translateResource( "cms:emailcenter.stats.panel.clickreport.link" )#</th>
										<th>#translateResource( "cms:emailcenter.stats.panel.clickreport.clicks" )#</th>
									</tr>
								</thead>
								<tbody>
									<cfloop query="args.clickReport">
										<tr>
											<td>
												<a href="#args.clickReport.link#" target="_blank">
													<i class="fa fa-fw fa-external-link"></i>
													#abbreviate( args.clickReport.link, 60 )#
												</a>
												<cfif Len( args.clickReport.link_body )>
													<em class="light-grey">(#abbreviate( args.clickReport.link_body, 30 )#)</em>
												<cfelseif Len( args.clickReport.link_title )>
													<em class="light-grey">(#abbreviate( args.clickReport.link_title, 30 )#)</em>
												</cfif>
											</td>
											<td>
												#LsNumberFormat( args.clickReport.clicks )#
											</td>
										</tr>
									</cfloop>
								</tbody>
							</table>
						</div>
					</div>
				</div>
			</cfif>
			<cfloop list="bounces,unsubscribes,complaints" item="stat">
				<cfif stats[ "has#stat#"]>
					<div class="panel">
						<div class="panel-heading">
							<h4 class="panel-title grey">
								<i class="fa fa-fw fa-user"></i>
								#translateResource( "cms:emailcenter.stats.panel.#stat#" )#
							</h4>
						</div>
						<div class="panel-body">
							#renderView( view="/admin/datamanager/_objectDataTable", args={
								  objectName        = "email_template_send_log"
								, useMultiActions   = false
								, datasourceUrl     = event.buildAdminLink( linkTo="emailCenter.getFilteredRecipientsForStatsTables", queryString="id=#args.templateId#&statType=#stat#" )
								, gridFields        = [ args.recipientStatField ?: "recipient", dateFields[ stat ] ]
								, draftsEnabled     = false
								, allowSearch       = false
								, allowFilter       = false
								, compact           = true
								, defaultPageLength = 5
							} )#
						</div>
					</div>
				</cfif>
			</cfloop>
		</div>
	</div>
</cfoutput>
