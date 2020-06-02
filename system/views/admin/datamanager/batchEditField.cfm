<cfscript>
	object = rc.object ?: "";
</cfscript>
<cfoutput>
	#renderViewlet( event="admin.datamanager._batchEditForm", args={
		  saveChangesAction = event.buildAdminLink( objectName=object, operation="batchEditAction" )
		, cancelAction      = event.buildAdminLink( objectName=object, operation="listing" )
		, ids               = rc.id     ?: ""
		, object            = object
		, field             = rc.field  ?: ""
	} )#
</cfoutput>
