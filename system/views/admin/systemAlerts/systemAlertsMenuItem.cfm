<!---@feature admin--->
<cfscript>
	levels      = args.levels      ?: [];
	alertCounts = args.alertCounts ?: {};
	totalAlerts = val( alertCounts.total ?: "" );
</cfscript>


<cfoutput>
	<li>
		<a id="systemAlertsNavBarItem" href="#event.buildAdminLink( objectName="system_alert" )#">
			<i class="fa fa-exclamation-triangle<cfif val( alertCounts.critical ?: "" )> icon-animated-bell</cfif>"></i>
			<span class="badge">#totalAlerts#</span>
		</a>
	</li>
</cfoutput>