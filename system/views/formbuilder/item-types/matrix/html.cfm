<!---@feature formbuilder--->
<cfparam name="args.answers" type="array" default=[] />

<cfoutput>
	<cfset total=ArrayLen( args.answers ) />
	<cfloop from="1" to="#total#" index="i">
		<strong>#args.answers[i].question#</strong>: #args.answers[i].answer#
		<cfif i neq total>
			<br>
		</cfif>
	</cfloop>
</cfoutput>