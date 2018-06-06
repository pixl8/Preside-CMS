<cfscript>
	language = prc.language ?: {};
	object   = prc.objectName ?: "";
	id       = prc.recordId ?: "";
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_objectVersionHistoryTable", args={
		  objectName    = object
		, datasourceUrl = event.buildAdminLink( linkTo="ajaxProxy", queryString="object=#object#&id=#id#&action=dataManager.getTranslationRecordHistoryForAjaxDataTables&gridFields=datemodified,_version_author,label&language=#language.id#" )
	} )#
</cfoutput>