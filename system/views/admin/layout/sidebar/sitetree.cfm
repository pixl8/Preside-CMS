<!---@feature admin and sitetree--->
<cfoutput>
	#renderViewlet( event="admin.layout.adminMenu", args={
		  menuItems       = [ "sitetree" ]
		, legacyViewBase  = "/deliberately/wrong/"
	} )#
</cfoutput>