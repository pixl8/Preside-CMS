<!---@feature admin and rulesEngine--->
<cfscript>
	invalidRules = args.data.invalidRules ?: [];
</cfscript>

<cfoutput>
	<cfif arrayLen( invalidRules )>
		<h3>#translateResource( uri="systemAlerts.invalidRuleEngineRules:render.no.of.invalid.rules", data=[ arrayLen( invalidRules ) ] )#</h3>

		<ul>
			<cfloop array="#invalidRules#" item="ruleId">
				<li>
					<a href="#event.buildAdminLink( objectName="rules_engine_condition", recordId=ruleId )#">
						#renderLabel( "rules_engine_condition", ruleId )#
					</a>
				</li>
			</cfloop>
		</ul>
	</cfif>
</cfoutput>