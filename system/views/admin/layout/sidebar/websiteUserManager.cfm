<!---@feature admin and websiteUsers--->
<cfoutput>
	#renderViewlet( event="admin.layout.adminMenu", args={
		  menuItems       = [ "websiteUserManager" ]
		, legacyViewBase  = "/deliberately/wrong/"
	} )#
</cfoutput>