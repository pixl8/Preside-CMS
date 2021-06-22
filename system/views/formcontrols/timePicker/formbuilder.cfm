<cfscript>
	event
		.include( "/css/frontend/formbuilder/timePicker/" )
		.include( "/js/frontend/formbuilder/timePicker/" )
	;
</cfscript>
<cfset args.timePickerClass = "formbuilder-time-picker" />
<cfoutput>
	#renderView( view="/formcontrols/timePicker/index", args=args )#
</cfoutput>