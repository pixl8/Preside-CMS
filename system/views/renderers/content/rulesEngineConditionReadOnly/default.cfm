<cfscript>
	expressions  = args.expressions ?: [];
	ruleContext  = args.ruleContext ?: "";
	filterObject = args.filterObject ?: "";
</cfscript>

<cfoutput>
	<cfif !IsArray( expressions ) || !ArrayLen( expressions )>
		<p class="alert alert-danger">
			<i class="fa fa-fw fa-exclamation-triangle"></i>
			#translateResource( "preside-objects.rules_engine_condition:renderer.error.no.expressions" )#
		</p>
	<cfelse>
		<ul class="rules-engine-expressions-read-only">
			<cfloop array="#expressions#" index="i" item="expression">
				#renderView( view="/renderers/content/rulesEngineConditionReadOnly/_expression", args={
					  expression   = expression
					, ruleContext  = ruleContext
					, filterObject = filterObject
					, depth        = 0
				} )#
			</cfloop>
		</ul>
	</cfif>
</cfoutput>