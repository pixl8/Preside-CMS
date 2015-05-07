<cfscript>
	languageId = rc.language ?: "";
	object     = prc.versionedObjectName ?: "page";
	id         = rc.id ?: "";
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName    = object
		, gridFields    = [ "datemodified", "_version_author", "title" ]
		, datasourceUrl = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=sitetree.getPageTranslationHistoryForAjaxDataTables&id=#id#&language=#languageId#" )
		, allowSearch   = false
	} )#
</cfoutput>