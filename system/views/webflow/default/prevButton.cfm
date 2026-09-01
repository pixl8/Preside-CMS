<!---@feature webflow--->
<cfscript>
	btnTitle = args.stepConfig.back_button ?: "";
	prevLink = args.prevLink ?: "";
	btnClass = "btn webflow-btn webflow-prev-btn";

	if ( !event.isAdminRequest() ) {
		btnClass &= " #Trim( translateResource( uri="webflow:button.prev.class", defaultValue="" ) )#";
	}
</cfscript>
<cfoutput>
	<div class="webflow-prev-btn-container">
		<a href="#prevLink#" rel="nofollow" class="#btnClass#">#btnTitle#</a>
	</div>
</cfoutput>
