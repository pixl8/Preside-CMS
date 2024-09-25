<!---@feature formbuilder--->
<cfscript>
	args.class                   = args.class ?: "form-control";
	args.removeObjectPickerClass = true;
</cfscript>

<cfoutput>
	#outputView( view="/formcontrols/urlInput/index", args=args )#
</cfoutput>