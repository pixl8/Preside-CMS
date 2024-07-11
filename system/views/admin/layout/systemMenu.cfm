<!---@feature admin--->
<cfscript>
	settingsMenu = renderViewlet( event="admin.layout.adminMenu", args={
		  menuItems       = getSetting( "adminConfigurationMenuItems" )
		, legacyViewBase  = "/admin/layout/configurationMenu/"
		, itemRenderer    = "/admin/layout/topnav/_subitem"
		, subItemRenderer = "/admin/layout/topnav/_subitem"
		, itemRendererArgs = { dropdownDirection="left" }
	} );
</cfscript>

<cfoutput>
	<cfif Len( Trim( settingsMenu ) )>
		<a data-toggle="dropdown" href="##" class="dropdown-toggle">
			<i class="fa fa-cogs"></i>
			#translateResource( "cms:configuration.menu.title" )#
			<i class="fa fa-caret-down"></i>
		</a>

		<ul class="dropdown-menu dropdown-yellow dropdown-caret dropdown-close">
			#settingsMenu#
		</ul>
	</cfif>
</cfoutput>