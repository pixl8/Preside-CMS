<!---@feature formbuilder--->
<cfscript>
	event
		.include( "/css/frontend/formbuilder/timePicker/" )
		.include( "/js/frontend/formbuilder/timePicker/" )
	;

	args.timePickerClass = "formbuilder-time-picker";
</cfscript>

<cfoutput>
	#outputView( view="/formcontrols/timePicker/index", args=args )#
</cfoutput>
