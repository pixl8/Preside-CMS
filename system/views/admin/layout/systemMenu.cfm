<cfset configItems = getSetting( "adminConfigurationMenuItems" ) />

<cfoutput>
	<cfsavecontent variable="settingsMenu">
		<cfloop array="#configItems#" item="item" index="i">
			#renderView( view="admin/layout/configurationMenu/#item#" )#
		</cfloop>
	</cfsavecontent>


	<cfif Len( Trim( settingsMenu ) )>
		<a data-toggle="dropdown" href="##" class="dropdown-toggle">
			<i class="fa fa-cogs"></i>
			#translateResource( "cms:configuration.menu.title" )#
			<i class="fa fa-caret-down"></i>
		</a>

		<ul class="pull-right dropdown-menu dropdown-yellow dropdown-caret dropdown-close">
			#settingsMenu#
		</ul>
	</cfif>
</cfoutput>