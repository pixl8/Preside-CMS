<cfscript>
	object = rc.object ?: "";
</cfscript>
<cfoutput>
	#renderViewlet( event="admin.datamanager._batchEditForm", args={
		  saveChangesAction = event.buildAdminLink( objectName=object, operation="batchEditAction" )
		, cancelAction      = event.buildAdminLink( objectName=object, operation="listing" )
		, ids               = rc.id     ?: ""
		, batchAll          = isTrue( prc.batchAll ?: "" )
		, batchSrcArgs      = rc.batchSrcArgs ?: ""
		, recordCount       = prc.recordCount ?: ListLen( rc.id ?: "" )
		, object            = object
		, field             = rc.field  ?: ""
	} )#
</cfoutput>
