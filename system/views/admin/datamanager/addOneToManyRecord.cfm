<cfscript>
	objectName      = rc.object          ?: "";
	parentId        = rc.parentId        ?: "";
	relationshipKey = rc.relationshipKey ?: "";
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_addOneToManyRecordForm", args={
		  objectName            = objectName
		, parentId              = parentId
		, relationshipKey       = relationshipKey
		, addRecordAction       = event.buildAdminLink( linkTo='datamanager.addOneToManyRecordAction', queryString="object=#objectName#" )
		, allowAddAnotherSwitch = true
	} )#
</cfoutput>