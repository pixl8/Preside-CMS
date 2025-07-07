<!---@feature webflow--->
<cfscript>
	svgLink     = args.svgLink     ?: "";
	fullSvgLink = args.fullSvgLink ?: "";
	stepstable  = args.stepstable  ?: "";
</cfscript>
<cfoutput>
	<div class="row">
		<div class="col-lg-8 col-md-9">#stepsTable#</div>
		<div class="col-lg-4 col-md-3">
			<div class="text-center">
				<a href="#fullSvgLink#">
					<img src="#svgLink#" style="max-height: 600px; max-width: 100%;">
				</a>
			</div>
		</div>
	</div>
</cfoutput>