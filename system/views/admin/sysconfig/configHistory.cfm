<cfscript>
	prc.pageIcon     = "history";
	prc.pageTitle    = translateResource( uri="cms:sysconfig.history.title", data=[ rc.id ] );
	prc.pageSubTitle = translateResource( uri="cms:sysconfig.history.subTitle" );

	id = rc.id ?: "";
</cfscript>

<cfoutput>
	#renderView( view="/admin/datamanager/_objectVersionHistoryTable", args={
		  objectName    = "system_config"
		, datasourceUrl = event.buildAdminLink( linkTo="ajaxProxy", queryString="action=SysConfig.getConfigHistoryForAjaxDataTables&id=#id#" )
	} )#
</cfoutput>