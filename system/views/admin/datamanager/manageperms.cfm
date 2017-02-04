<cfscript>
	object              = rc.object ?: "";
	objectTitleSingular = translateResource( uri="preside-objects.#object#:title.singular", defaultValue=object );

	prc.pageIcon     = "lock";
	prc.pageTitle    = translateResource( uri="cms:datamanager.manageperms.title", data=[  objectTitleSingular  ] );;
	prc.pageSubTitle = translateResource( uri="cms:datamanager.manageperms.subtitle", data=[  objectTitleSingular  ] );;
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