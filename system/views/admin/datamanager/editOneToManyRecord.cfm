<cfscript>
	record          = prc.record         ?: "";
	object          = rc.object          ?: "";
	parentId        = rc.parentId        ?: "";
	relationshipKey = rc.relationshipKey ?: "";
	id              = rc.id              ?: "";
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_editOneToManyRecordForm", args={
		  object          = object
		, id              = id
		, parentId        = parentId
		, relationshipKey = relationshipKey
		, record          = record
	} )#
</cfoutput>