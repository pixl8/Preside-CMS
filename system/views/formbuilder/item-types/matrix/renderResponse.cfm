<cfparam name="args.answers" type="array" />

<cfoutput>
	<cfloop from="1" to="#args.answers.len()#" index="i">
		<strong>#args.answers[i].question#</strong>: #args.answers[i].answer#
		<cfif i != args.answers.len()>
			<br>
		</cfif>
	</cfloop>
</cfoutput>