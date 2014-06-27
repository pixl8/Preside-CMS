<cfscript>
	object              = rc.object ?: ""
	objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object ?: "" );
	editRecordTitle     = translateResource( uri="cms:datamanager.editrecord.title", data=[ LCase( objectTitleSingular ) ] );
	useVersioning       = prc.useVersioning ?: false;

	prc.pageIcon  = "pencil";
	prc.pageTitle = editRecordTitle;
</cfscript>

<cfoutput>
	<cfif useVersioning>
		#renderViewlet( event='admin.datamanager.versionNavigator', args={ object=rc.object ?: "", id=rc.id ?: "", version=rc.version ?: "" } )#
	</cfif>

	#renderView( view="/admin/datamanager/_editRecordForm", args={
		  object        = ( rc.object  ?: "" )
		, id            = ( rc.id      ?: "" )
		, version       = ( rc.version ?: "" )
		, record        = ( prc.record ?: {} )
		, useVersioning = ( prc.useVersioning ?: false )
	} )#
</cfoutput>