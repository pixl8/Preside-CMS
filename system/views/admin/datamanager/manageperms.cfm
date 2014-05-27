<cfscript>
	object              = rc.object ?: ""
	objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );
	managePermsTitle    = translateResource( uri="cms:datamanager.manageperms.title", data=[ LCase( objectTitleSingular ) ] );

	prc.pageIcon  = "lock";
	prc.pageTitle = managePermsTitle;
</cfscript>

<cfoutput>
	#renderViewlet( event="admin.permissions.contextPermsForm", args={
		  permissionKeys = [ "datamanager.*" ]
		, context        = "datamanager"
		, contextKey     = object
		, saveAction     = event.buildAdminLink( linkTo="datamanager.savePermsAction", queryString="object=#object#" )
		, cancelAction   = event.buildAdminLink( linkTo="datamanager.object"         , queryString="id=#object#"     )
	} )#
</cfoutput>