<cfscript>
	pageId     = rc.id    ?: "";
	pageRecord = prc.page ?: QueryNew( 'title' );

	prc.pageIcon     = "lock";
	prc.pageTitle    = translateResource( uri="cms:sitetree.editPagePermissions.title", data=[ pageRecord.title ] );;
	prc.pageSubTitle = translateResource( uri="cms:sitetree.editPagePermissions.subtitle", data=[ pageRecord.title ] );;
</cfscript>

<cfoutput>
	#renderViewlet( event="admin.permissions.contextPermsForm", args={
		  permissionKeys       = [ "sitetree.*", "!sitetree.viewtrash", "!sitetree.emptytrash", "!sitetree.restore", "!sitetree.delete" ]
		, context              = "page"
		, contextKey           = pageId
		, inheritedContextKeys = prc.inheritedPermissionContext ?: []
		, saveAction           = event.buildAdminLink( linkTo="sitetree.editPagePermissionsAction", queryString="id=#pageId#" )
		, cancelAction         = event.buildAdminLink( linkTo="sitetree.index", queryString="selected=#pageId#" )
	} )#
</cfoutput>