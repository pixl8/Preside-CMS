<cfscript>
	object = rc.object ?: "";
</cfscript>

<cfoutput>
	#renderViewlet( event="admin.permissions.contextPermsForm", args={
		  permissionKeys = [ "datamanager.*" ]
		, context        = "datamanager"
		, contextKey     = object
		, saveAction     = event.buildAdminLink( linkTo="datamanager.savePermsAction", queryString="object=#object#" )
		, cancelAction   = event.buildAdminLink( objectName=object, operation="listing" )
	} )#
</cfoutput>