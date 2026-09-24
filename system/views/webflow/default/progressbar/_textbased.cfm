<cfscript>
	stepCount          = Val( args.stepCount         ?: "" );
	currentStepNumber  = Val( args.currentStepNumber ?: "" );
	currentStepTitle   = Trim( args.currentStepTitle ?: "" );
	progressBarClass   = args.progressBarClass ?: getSetting( "webflow.layout.progressBar.class" );
</cfscript>

<cfoutput>
	<div class="webflow-progress-bar #progressBarClass#">
		<span class="webflow-progress-bar-progress-title">
			#renderEnum(
				  data            = "textbased"
				, enum            = "webflowProgressBarType"
				, property        = "progress.title"
				, translationData = [ currentStepNumber, stepCount ]
			)#
		</span>
		<h5 class="webflow-progress-bar-step-title">#currentStepTitle#</h5>
	</div>
</cfoutput>