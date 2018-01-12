<cfscript>
	preRenderListing  = prc.preRenderListing  ?: "";
	postRenderListing = prc.postRenderListing ?: "";
	listingView       = prc.listingView     ?: "";
	topRightButtons   = prc.topRightButtons ?: "";
</cfscript>
<cfoutput>
	<cfif topRightButtons.len()>
		<div class="top-right-button-group">#topRightButtons#</div>
	</cfif>

	#preRenderListing#
	#listingView#
	#postRenderListing#
</cfoutput>