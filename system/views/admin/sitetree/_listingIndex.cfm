<cfscript>
	renderViewlet( event="admin.datamanager.object", private=false, object="page", objectName="page", prePostExempt=false, args=args );
</cfscript>

<cfoutput>
	#prc.preRenderListing#
	#prc.listingView#
	#prc.postRenderListing#
</cfoutput>