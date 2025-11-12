<!---@feature webflow--->
<cfscript>
	progressIndicators = args.progressIndicators ?: [];
	stepCount          = Val( args.stepCount         ?: "" );
	currentStepNumber  = Val( args.currentStepNumber ?: "" );
</cfscript>

<cfoutput>
	<ul class="steps">
		<cfloop array="#progressIndicators#" item="step" index="i">
			<li class="webflow-progress-bar-item #step.class#" title="#HtmlEditFormat( step.title )#"<cfif step.status == "active"> aria-current="step"</cfif>>
				<span class="step">#i#</span>
				<span class="title">
					<cfif Len( step.link )>
						<a href="#step.link#">#step.title#</a>
					<cfelse>
						#step.title#
					</cfif>
				</span>
			</li>
		</cfloop>
	</ul>
</cfoutput>