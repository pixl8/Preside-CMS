<cfscript>
	ruleId = args.reference ?: "";
</cfscript>

<cfoutput>
	<cfif len( ruleId )>
		<p>#translateResource( uri="systemAlerts.invalidRuleEngineRules:render.invalid.condition", data=[ renderLabel( "rules_engine_condition", ruleId ) ] )#</p>

		<a class="btn btn-warning" href="#event.buildAdminLink( objectName="rules_engine_condition", recordId=ruleId )#">
			#translateResource( uri="systemAlerts.invalidRuleEngineRules:render.invalid.condition.fix" )#
		</a>
	</cfif>
</cfoutput>