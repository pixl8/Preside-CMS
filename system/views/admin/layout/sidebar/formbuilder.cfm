<!---@feature admin and formbuilder--->
<cfoutput>
	#renderViewlet( event="admin.layout.adminMenu", args={
		  menuItems       = [ "formbuilder" ]
		, legacyViewBase  = "/deliberately/wrong/"
	} )#
</cfoutput>