<cfscript>
	event
		.include( "/css/frontend/formbuilder/datePicker/" )
		.include( "/js/frontend/formbuilder/datePicker/" )
	;
</cfscript>
<cfset args.datePickerClass = "formbuilder-date-picker" />
<cfoutput>#renderView( view="/formcontrols/datePicker/index", args=args )#</cfoutput>