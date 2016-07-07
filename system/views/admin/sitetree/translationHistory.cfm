<cfscript>
	languageId = rc.language ?: "";
	object     = prc.versionedObjectName ?: "page";
	id         = rc.id ?: "";
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_objectVersionHistoryTable", args={
		  objectName    = object
		, datasourceUrl = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=sitetree.getPageTranslationHistoryForAjaxDataTables&id=#id#&language=#languageId#" )
	} )#
</cfoutput>