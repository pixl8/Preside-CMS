<cfscript>
	siteId = rc.id ?: "";
</cfscript>

<cfoutput>
	#renderViewlet( event="admin.permissions.contextPermsForm", args={
	      permissionKeys = [ "sites.navigate" ]
	    , context        = "site"
	    , contextKey     = siteId
	    , saveAction     = event.buildAdminLink( linkTo="sites.saveSitePermissionsAction", querystring="id=#siteId#" )
	    , cancelAction   = event.buildAdminLink( linkTo="sites.manage", querystring="id=#siteId#" )
	} )#
</cfoutput>