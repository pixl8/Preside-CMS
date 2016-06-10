<cfscript>
	logs = prc.logs ?: [];
</cfscript>
<cfoutput>
	<cfif logs.recordcount>
		<div id="audit-trail">
			<div class="row">
				<div class="col-xs-12 col-sm-10 col-sm-offset-1">
					<div class="timeline-container">
						#renderView( view="/admin/auditTrail/_logs", args={ logs=logs } )#
					</div>
				</div>
			</div>
		</div>
		<div class="load-more text-center">
			<a class="load-more btn btn-primary" data-load-more-target="audit-trail" data-href="#event.buildAdminLink( linkTo='auditTrail.loadMore', queryString='page=' )#"><i class="fa fa-plus-circle"></i> #translateResource( uri='cms:auditTrail.loadMore' )#</a>
		</div>
	<cfelse>
		<p><em>#translateResource( uri='cms:auditTrail.noData' )#</em></p>
	</cfif>
</cfoutput>