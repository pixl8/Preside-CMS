<!---@feature webflow--->
<cfscript>
	title = args.stepConfig.title ?: "";
	level = args.stepTitleLevel   ?: 2;
	class = args.stepTitleClass   ?: "webflow-step-title";
</cfscript>
<cfif Len( Trim( title ) )>
	<cfoutput><h#level# class="#class#">#title#</h#level#></cfoutput>
</cfif>