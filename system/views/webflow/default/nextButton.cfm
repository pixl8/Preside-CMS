<!---@feature webflow--->
<cfscript>
	btnTitle = args.stepConfig.next_button ?: "";
	btnClass = "btn webflow-btn webflow-next-btn";

	if ( !event.isAdminRequest() ) {
		btnClass &= " #Trim( translateResource( uri="webflow:button.next.class", defaultValue="" ) )#";
	} else {
		btnClass &= " btn-primary";
	}
</cfscript>
<cfoutput>
	<div class="webflow-next-btn-container">
		<button class="#btnClass#" type="submit" tabindex="#getNextTabIndex()#" default>#btnTitle#</button>
	</div>
</cfoutput>
