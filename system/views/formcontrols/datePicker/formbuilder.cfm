<!---@feature formbuilder--->
<cfscript>
	event
		.include( "/css/frontend/formbuilder/datePicker/" )
		.include( "/js/frontend/formbuilder/datePicker/" )
	;

	args.datePickerClass = "formbuilder-date-picker";
</cfscript>
<cfoutput>#renderViewlet( event="formcontrols.datePicker.index", args=args )#</cfoutput>