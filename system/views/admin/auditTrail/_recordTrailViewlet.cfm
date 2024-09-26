<!---@feature admin--->
<cfscript>
	logs        = args.logs     ?: [];
	recordId    = args.recordId ?: "";
	hasMore     = isTrue( args.hasMore ?: "" );
	loadMoreUrl = event.buildAdminLink( linkTo='auditTrail.loadMore', queryString='recordId=#recordId#&page=' );
</cfscript>
<cfoutput>
	<cfif logs.recordcount>
		<div class="timeline-container" id="audit-trail">
			#renderView( view="/admin/auditTrail/_logs", args={ logs=logs } )#
		</div>
		<cfif hasMore>
			<div class="load-more text-center">
				<a class="load-more-logs btn btn-primary" data-load-more-target="audit-trail" data-href="#loadMoreUrl#"><i class="fa fa-plus-circle"></i> #translateResource( uri='cms:auditTrail.loadMore' )#</a>
			</div>
		</cfif>
	<cfelse>
		<p><em>#translateResource( uri='cms:auditTrail.noData' )#</em></p>
	</cfif>
</cfoutput>