<!---@feature admin and dataManager--->
<cfoutput>
	#renderViewlet( event="admin.layout.adminMenu", args={
		  menuItems       = [ "datamanager" ]
		, legacyViewBase  = "/deliberately/wrong/"
	} )#
</cfoutput>