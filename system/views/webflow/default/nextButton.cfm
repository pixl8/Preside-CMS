<!---@feature webflow--->
<cfscript>
	btnTitle = args.stepConfig.next_button ?: "";
</cfscript>
<cfoutput>
	<div class="webflow-next-btn-container">
		<button class="btn btn-primary webflow-btn webflow-next-btn" type="submit" tabindex="#getNextTabIndex()#" default>#btnTitle#</button>
	</div>
</cfoutput>