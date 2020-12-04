<cfscript>
	depth        = Val( args.depth ?: 0 );
	expression   = args.expression ?: "";
	ruleContext  = args.ruleContext ?: "";
	filterObject = args.filterObject ?: "";
</cfscript>
<cfoutput>
	<cfif IsSimpleValue( expression )>
		<li class="rules-engine-join rules-engine-#LCase( expression )#">
			#translateResource( "cms:rulesEngine.join.#LCase( expression )#" )#
		</li>
	<cfelseif IsArray( expression )>
		<li class="rules-engine-expression-group">
			<ul class="rules-engine-expressions-read-only-sub-expressions" data-depth="#depth+1#">
				<cfloop array="#expression#" index="n" item="exp">
					#renderView( view="/renderers/content/rulesEngineConditionReadOnly/_expression", args={
						  expression = exp
						, depth      = depth+1
					} )#
				</cfloop>
			</ul>
		</li>
	<cfelse>
		<li class="rules-engine-expression">
			#renderContent( renderer="rulesEngineExpressionReadOnly", data=expression, args={
				  ruleContext  = args.ruleContext  ?: ""
				, filterObject = args.filterObject ?: ""
			} )#
		</li>
	</cfif>
</cfoutput>