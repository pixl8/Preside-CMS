<cfscript>
	logs        = prc.logs    ?: [];
	dateFrom    = rc.dateFrom ?: "";
	dateTo      = rc.dateTo   ?: "";
	user        = rc.user     ?: "";
	action      = rc.action   ?: "";
	recordId    = rc.recordId ?: "";
	loadMoreUrl = event.buildAdminLink( linkTo='auditTrail.loadMore', queryString='dateFrom=#dateFrom#&dateTo=#dateTo#&user=#user#&action=#action#&recordId=#recordId#&page=' );
</cfscript>
<cfoutput>
	<div class="top-right-button-group">
		<a class="pull-right inline" href="##filter-form" data-toggle="collapse">
			<button class="btn btn-info">
				<i class="fa fa-filter"></i>
				#translateResource( "cms:toggle.filter.btn")#
			</button>
		</a>
	</div>

	<div class="collapse" id="filter-form">
		<form class="form-horizontal" method="get" action="">
			#renderForm(
				  formName = "audittrail.filter"
				, context  = "admin"
			)#

			<br>

			<div class="row">
				<div class="col-md-offset-2">
					<a href="##filter-form" data-toggle="collapse">
						<i class="fa fa-fw fa-reply bigger-110"></i>
						#translateResource( "cms:cancel.btn" )#
					</a>

					&nbsp;

					<button class="btn btn-info" type="submit" tabindex="#getNextTabIndex()#">
						<i class="fa fa-fw fa-check bigger-110"></i>
						#translateResource( "cms:ok.btn" )#
					</button>
				</div>
			</div>
		</form>
	</div>

	<cfif logs.recordcount>
		<div class="timeline-container" id="audit-trail">
			#renderView( view="/admin/auditTrail/_logs", args={ logs=logs } )#
		</div>
		<div class="load-more text-center">
			<a class="load-more-logs btn btn-primary" data-load-more-target="audit-trail" data-href="#loadMoreUrl#"><i class="fa fa-plus-circle"></i> #translateResource( uri='cms:auditTrail.loadMore' )#</a>
		</div>
	<cfelse>
		<p><em>#translateResource( uri='cms:auditTrail.noData' )#</em></p>
	</cfif>
</cfoutput>