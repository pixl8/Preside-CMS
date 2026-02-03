<!---@feature admin and assetManager--->
<cfoutput>
	#renderViewlet( event="admin.layout.adminMenu", args={
		  menuItems       = [ "assetmanager" ]
		, legacyViewBase  = "/deliberately/wrong/"
	} )#
</cfoutput>