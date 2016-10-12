<cfscript>
	objectName          = rc.object ?: "";
	objectTitleSingular = translateResource( uri="preside-objects.#objectName#:title.singular", defaultValue=objectName );
	addRecordTitle      = translateResource( uri="cms:datamanager.addrecord.title", data=[ LCase( objectTitleSingular ) ] );

	prc.pageIcon  = "plus";
	prc.pageTitle = addRecordTitle;
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_addRecordForm", args={
		  objectName            = objectName
		, addRecordAction       = event.buildAdminLink( linkTo='datamanager.addRecordAction', queryString="object=#objectName#" )
		, allowAddAnotherSwitch = true
		, draftsEnabled         = IsTrue( prc.draftsEnabled ?: "" )
		, canSaveDraft          = IsTrue( prc.canSaveDraft  ?: "" )
		, canPublish            = IsTrue( prc.canPublish    ?: "" )
	} )#
</cfoutput>