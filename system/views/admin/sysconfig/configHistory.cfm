<cfscript>
	prc.pageIcon  = "history";
	prc.pageTitle = "Config history";
	prc.pageSubTitle = "Config history";
	// prc.pageSubTitle = translateResource( uri="cms:sitetree.configHistory.subtitle", data=[ prc.page.title ] );

	id = rc.id ?: "";
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_objectVersionHistoryTable", args={
		  objectName    = "system_config"
		, datasourceUrl = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=SysConfig.getConfigHistoryForAjaxDataTables&id=#id#" )
	} )#
</cfoutput>