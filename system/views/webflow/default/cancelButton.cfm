<!---@feature webflow--->
<cfscript>
	btnTitle   = args.stepConfig.cancel_button ?: "";
	cancelLink = args.cancelLink ?: "";
	btnClass   = "webflow-cancel-btn";

	if ( !Len( Trim( btnTitle ) ) ) {
		btnTitle = translateResource( "webflow:cancel" );
	}

	if ( !event.isAdminRequest() ) {
		btnClass &= " btn webflow-btn #Trim( translateResource( uri="webflow:button.cancel.class", defaultValue="" ) )#";
	}
</cfscript>
<cfoutput>
	<div class="webflow-cancel-btn-container">
		<a href="#cancelLink#" class="#btnClass#" type="submit" default>#btnTitle#</a>
	</div>
</cfoutput>
