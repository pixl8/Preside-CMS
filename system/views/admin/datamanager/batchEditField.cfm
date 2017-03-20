<cfoutput>
	#renderViewlet( event="admin.datamanager._batchEditForm", args={
		  saveChangesAction = event.buildAdminLink( linkTo='datamanager.batchEditAction')
		, cancelAction      = event.buildAdminLink( linkTo="datamanager.object", querystring='id=#object#' )
		, ids               = rc.id     ?: ""
		, object            = rc.object ?: ""
		, field             = rc.field  ?: ""
	} )#
</cfoutput>
