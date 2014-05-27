<cfscript>
	object              = rc.object ?: ""
	objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object ?: "" );
	editRecordTitle     = translateResource( uri="cms:datamanager.editrecord.title", data=[ LCase( objectTitleSingular ) ] );

	prc.pageIcon  = "pencil";
	prc.pageTitle = editRecordTitle;
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object        = ( rc.object  ?: "" )
		, id            = ( rc.id      ?: "" )
		, record        = ( prc.record ?: {} )
		, useVersioning = ( prc.useVersioning ?: false )
	} )#
</cfoutput>