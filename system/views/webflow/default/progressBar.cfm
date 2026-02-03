<!---@feature webflow--->
<cfscript>
	progressIndicators = args.progressIndicators ?: [];
	stepCount          = Val( args.stepCount         ?: "" );
	currentStepNumber  = Val( args.currentStepNumber ?: "" );
	progressBarClass   = args.progressBarClass ?: getSetting( "webflow.layout.progressBar.class" );
</cfscript>

<cfoutput>
	<div class="webflow-progress-bar #progressBarClass#">
		<ol class="webflow-progress-bar-list" role="progressbar" aria-valuemin="1" aria-valuemax="#stepCount#" aria-valuenow="#currentStepNumber#">
			<cfloop array="#progressIndicators#" item="step" index="i">
				<li class="webflow-progress-bar-item #step.class#" title="#HtmlEditFormat( step.title )#"<cfif step.status == "active"> aria-current="step"</cfif>>
					<cfif Len( step.link )>
						<a href="#step.link#" class="webflow-progress-bar-item-title webflow-progress-bar-item-link"><span class="webflow-progress-bar-item-text">#step.title#</span></a>
					<cfelse>
						<span class="webflow-progress-bar-item-title"><span class="webflow-progress-bar-item-text">#step.title#</span></span>
					</cfif>
				</li>
			</cfloop>
		</ol>
	</div>
</cfoutput>