<cfscript>
	prc.pageIcon  = "history";
	prc.pageTitle = translateResource( uri="cms:sitetree.pageHistory.title", data=[ prc.page.label ] );
	prc.pageSubTitle = translateResource( uri="cms:sitetree.pageHistory.subtitle", data=[ prc.page.label ] );

	id = rc.id ?: ""
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_objectDataTable", args={
		  objectName    = "page"
		, gridFields    = [ "datemodified", "_version_author", "label" ]
		, datasourceUrl = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=sitetree.getPageHistoryForAjaxDataTables&id=#id#" )
		, allowSearch   = false
	} )#
</cfoutput>