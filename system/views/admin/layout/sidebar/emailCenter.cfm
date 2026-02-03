<!---@feature admin and emailCenter--->
<cfoutput>
	#renderViewlet( event="admin.layout.adminMenu", args={
		  menuItems       = [ "emailCenter" ]
		, legacyViewBase  = "/deliberately/wrong/"
	} )#
</cfoutput>