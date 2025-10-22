<!---@feature webflow--->
<cfscript>
	content = Trim( args.content ?: "" );
</cfscript>

<cfoutput>
	<div class="webflow-form-ajax-submit">
		#content#
	</div>
</cfoutput>