<!---@feature admin--->
<!---
 * This file exists purely for backward compatibility.
 * This just proxies the "new" admin menu system (https://presidecms.atlassian.net/browse/PRESIDECMS-2293)
 * Exists for any systems/extensions that are referencing this file directly
 *
--->
<cfoutput>
	#renderViewlet( event="admin.layout.adminMenu", args={
		  menuItems       = [ "systemInformation" ]
		, legacyViewBase  = "/deliberately/wrong/"
		, itemRenderer    = "/admin/layout/topnav/_subitem"
		, subItemRenderer = "/admin/layout/topnav/_subitem"
		, itemRendererArgs = { dropdownDirection="left" }
	} )#
</cfoutput>