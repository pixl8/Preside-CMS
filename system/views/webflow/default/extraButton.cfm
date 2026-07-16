<!---@feature webflow--->
<cfscript>
	btnTitle       = Trim( args.additionalActionLabel ?: "" );
	btnLink        = Trim( args.additionalActionUrl   ?: "" );
	btnClass       = Trim( args.additionalActionClass ?: "" );
	groupWith      = LCase( Trim( args.extraButtonGroupWith ?: "next" ) );
	containerClass = "webflow-extra-btn-container";

	if ( groupWith == "prev" || groupWith == "standalone" ) {
		containerClass &= " webflow-extra-btn-container-#groupWith#";
	} else {
		containerClass &= " webflow-extra-btn-container-next";
	}

	if ( !Len( btnClass ) && !event.isAdminRequest() ) {
		btnClass = Trim( translateResource( uri="webflow:button.extra.class", defaultValue="" ) );
	}
</cfscript>
<cfoutput>
	<div class="#containerClass#">
		<a href="#btnLink#" rel="nofollow" class="btn webflow-btn webflow-extra-btn #btnClass#">#btnTitle#</a>
	</div>
</cfoutput>
