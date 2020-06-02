<cfscript>
	recordId = rc.id ?: "";
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object           = "rest_user"
		, id               = rc.id      ?: ""
		, record           = prc.record ?: {}
		, editRecordAction = event.buildAdminLink( linkTo='apiUserManager.editAction' )
		, cancelAction     = event.buildAdminLink( linkTo='apiUserManager' )
		, useVersioning    = false
	} )#
</cfoutput>