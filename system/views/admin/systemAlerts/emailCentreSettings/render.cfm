<!---@feature admin and emailCenter--->
<cfscript>
	issues       = args.data.issues ?: [];
	settingsLink = event.buildAdminLink( linkTo="emailcenter.settings" );
</cfscript>

<cfoutput>
	<p>#translateResource( "systemAlerts.emailCentreSettings:render.intro" )#</p>

	<ul>
		<cfloop array="#issues#" index="issue">
			<li>#translateResource( "systemAlerts.emailCentreSettings:render.issues.#issue#" )#</li>
		</cfloop>
	</ul>

	<p>#translateResource( uri="systemAlerts.emailCentreSettings:render.footer", data=[ settingsLink ] )#</p>
</cfoutput>