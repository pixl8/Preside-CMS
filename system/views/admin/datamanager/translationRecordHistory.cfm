<cfscript>
	language            = prc.language ?: {};
	object              = rc.object ?: ""
	id                  = rc.id ?: "";
	recordLabel         = prc.recordLabel ?: "Unknown";
	objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object ?: "" );
	recordHistoryTitle  = translateResource( uri="cms:datamanager.translationRecordhistory.title", data=[ recordLabel, LCase( objectTitleSingular ), language.name ] );

	prc.pageIcon  = "history";
	prc.pageTitle = recordHistoryTitle;
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_objectVersionHistoryTable", args={
		  objectName    = object
		, datasourceUrl = event.buildAdminLink( linkTo="ajaxProxy", queryString="object=#object#&id=#id#&action=dataManager.getTranslationRecordHistoryForAjaxDataTables&gridFields=datemodified,_version_author,label&language=#language.id#" )
	} )#
</cfoutput>