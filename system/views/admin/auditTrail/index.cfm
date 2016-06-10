<cfscript>
	logs = prc.logs ?: [];
</cfscript>
<cfoutput>
	<cfif logs.recordcount>
		<div class="timeline-container" id="audit-trail">
			#renderView( view="/admin/auditTrail/_logs", args={ logs=logs } )#
		</div>
		<div class="load-more text-center">
			<a class="load-more-logs btn btn-primary" data-load-more-target="audit-trail" data-href="#event.buildAdminLink( linkTo='auditTrail.loadMore', queryString='page=' )#"><i class="fa fa-plus-circle"></i> #translateResource( uri='cms:auditTrail.loadMore' )#</a>
		</div>
	<cfelse>
		<p><em>#translateResource( uri='cms:auditTrail.noData' )#</em></p>
	</cfif>
</cfoutput>