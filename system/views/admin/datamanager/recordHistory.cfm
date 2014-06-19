<cfscript>
	object              = rc.object ?: ""
	objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object ?: "" );
	recordHistoryTitle  = translateResource( uri="cms:datamanager.recordhistory.title", data=[ prc.record.label ?: "unknown", LCase( objectTitleSingular ) ] );

	prc.pageIcon  = "history";
	prc.pageTitle = recordHistoryTitle;
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_recordHistoryTable" )#
</cfoutput>