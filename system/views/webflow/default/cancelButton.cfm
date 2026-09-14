<!---@feature webflow--->
<cfscript>
	btnTitle   = args.stepConfig.cancel_button ?: "";
	cancelLink = args.cancelLink ?: "";

	if ( !Len( Trim( btnTitle ) ) ) {
		btnTitle = translateResource( "webflow:cancel" );
	}
</cfscript>
<cfoutput>
	<div class="webflow-cancel-btn-container">
		<a href="#cancelLink#" class="webflow-cancel-btn" type="submit" default>#btnTitle#</a>
	</div>
</cfoutput>