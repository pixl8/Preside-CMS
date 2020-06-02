<cfparam name="args.activeStep" type="numeric" default="1"/>

<cfscript>
	steps = [
		  translateResource( "cms:assetmanager.upload.steps.one"   )
		, translateResource( "cms:assetmanager.upload.steps.two"   )
		, translateResource( "cms:assetmanager.upload.steps.three" )
	];
</cfscript>

<cfoutput>
	<ul class="steps">
		<cfloop array="#steps#" index="i" item="step">
			<li data-step="#i#"<cfif i == args.activeStep> class="active"<cfelseif i lt args.activeStep> class="complete"</cfif>>
				<span class="step">#i#</span>
				<span class="title">#step#</span>
			</li>
		</cfloop>
	</ul>
	<hr>
</cfoutput>