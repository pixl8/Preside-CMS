<cfparam name="prc.log"      type="struct" />
<cfparam name="prc.activity" type="query"  />

<cfscript>
	logDate  = DateFormat( prc.log.datecreated, "yyyy-mm-dd" );
</cfscript>

<cfoutput>
	<div class="well">
		<div class="pull-right">
			<a href="#event.buildAdminLink( linkTo="emailCenter.logs.resendEmail", queryString="id=#prc.log.id#" )#" class="btn btn-primary load-in-place"><i class="fa fa-refresh"></i> #translateResource( "cms:mailcenter.logs.action.resend" )#</a>
		</div>
		<h2>#prc.log.subject#</h2>
		<dl class="dl-horizontal">
			<dt>#translateResource( "cms:mailcenter.logs.metadata.to.label" )#</dt>
			<dd>#prc.log.recipient#</dd>
			<dt>#translateResource( "cms:mailcenter.logs.metadata.from.label" )#</dt>
			<dd>#prc.log.sender#</dd>
			<dt>#translateResource( "cms:mailcenter.logs.metadata.template.label" )#</dt>
			<dd>#prc.log.name#</dd>
			<cfif len( prc.log.resend_of )>
				<dt>#translateResource( "cms:mailcenter.logs.metadata.resent.label" )#</dt>
				<dd><a href="#event.buildAdminLink( linkTo="emailCenter.logs.viewLog", queryString="id=#prc.log.resend_of#" )#" class="load-in-place">#translateResource( "cms:mailcenter.logs.metadata.resent.link" )#</a></dd>
			</cfif>
		</dl>
	</div>
	<div class="modal-padding-horizontal">
		<div class="timeline-container">
			#renderView( view="/admin/auditTrail/_logDateBanner", args={ logDate = logDate } )#

			#renderView( view="/admin/emailcenter/logs/_logActivity", args={
				  logDate         = prc.log.datecreated
				, emailAddress    = prc.log.recipient
				, datecreated     = prc.log.datecreated
				, actionIconClass = "fa-envelope-o"
				, actionTitle     = translateResource( "cms:mailcenter.logs.action.prepared.title" )
				, message         = translateResource( "cms:mailcenter.logs.action.prepared.message" )
			} )#

			<cfif IsTrue( prc.log.sent )>
				#renderView( view="/admin/emailcenter/logs/_logActivity", args={
					  logDate         = prc.log.sent_date
					, emailAddress    = prc.log.recipient
					, datecreated     = prc.log.sent_date
					, actionIconClass = "fa-paper-plane"
					, actionTitle     = translateResource( "cms:mailcenter.logs.action.sent.title" )
					, message         = translateResource( "cms:mailcenter.logs.action.sent.message" )
				} )#
			</cfif>

			<cfif IsTrue( prc.log.failed )>
				#renderView( view="/admin/emailcenter/logs/_logActivity", args={
					  logDate         = prc.log.failed_date
					, emailAddress    = prc.log.recipient
					, datecreated     = prc.log.failed_date
					, actionIconClass = "fa-exclamation-circle red"
					, actionTitle     = translateResource( uri="cms:mailcenter.logs.action.failed.title" )
					, message         = translateResource( uri="cms:mailcenter.logs.action.failed.message", data=[ prc.log.failed_reason ] )
				} )#
			</cfif>

			<cfif IsTrue( prc.log.delivered )>
				<cfset deliveredDate = IsDate( prc.log.delivered_date ) ? prc.log.delivered_date : prc.log.sent_date />

				#renderView( view="/admin/emailcenter/logs/_logActivity", args={
					  logDate         = deliveredDate
					, emailAddress    = prc.log.recipient
					, datecreated     = deliveredDate
					, actionIconClass = "fa-check green"
					, actionTitle     = translateResource( "cms:mailcenter.logs.action.delivered.title" )
					, message         = translateResource( "cms:mailcenter.logs.action.delivered.message" )
				} )#
			</cfif>


			<cfloop query="#prc.activity#">
				<cfif DateDiff( "d", prc.activity.datecreated, logDate )>
					<cfset logDate = DateFormat( prc.activity.datecreated, "yyyy-mm-dd" ) />
					</div>
					#renderView( view="/admin/auditTrail/_logDateBanner", args={ logDate = logDate } )#
					<div class="timeline-items">
				</cfif>

				<cfswitch expression="#prc.activity.activity_type#">
					<cfcase value="open">
						<cfset logIcon    = "fa-eye" />
						<cfset logTitle   = translateResource( "cms:mailcenter.logs.action.opened.title" ) />
						<cfset logMessage = translateResource( "cms:mailcenter.logs.action.opened.message" ) />
					</cfcase>
					<cfcase value="click">
						<cfset logIcon    = "fa-mouse-pointer" />
						<cfset logTitle   = translateResource( "cms:mailcenter.logs.action.clicked.title" ) />
						<cfset data       = DeserializeJson( prc.activity.extra_data ) />
						<cfset link       = '<a>#Trim( data.link ?: "unknown" )#</a>' />
						<cfset logMessage = translateResource( uri="cms:mailcenter.logs.action.clicked.message", data=[ link ] ) />
					</cfcase>
					<cfcase value="resend">
						<cfset logIcon    = "fa-refresh" />
						<cfset linkTitle  = translateResource( "cms:mailcenter.logs.action.resend.link.title" ) />
						<cfset data       = DeserializeJson( prc.activity.extra_data ) />
						<cfset link       = '<a class="load-in-place" href="#event.buildAdminLink( linkTo="emailCenter.logs.viewLog", queryString="id=#data.resentMessageId#" )#">#linkTitle#</a>' />
						<cfset logTitle   = translateResource( "cms:mailcenter.logs.action.resend.title" ) />
						<cfset logMessage = translateResource( uri="cms:mailcenter.logs.action.resend.message", data=[ link ] ) />
					</cfcase>
				</cfswitch>

				#renderView( view="/admin/emailcenter/logs/_logActivity", args={
					  logDate         = prc.activity.datecreated
					, emailAddress    = prc.log.recipient
					, datecreated     = prc.activity.datecreated
					, actionIconClass = logIcon
					, actionTitle     = logTitle
					, message         = logMessage
					, ipAddress       = prc.activity.user_ip
					, userAgent       = prc.activity.user_agent
					, showAuditTrail  = prc.activity.activity_type != "resend"
				} )#
			</cfloop>
		</div>
	</div>
</cfoutput>