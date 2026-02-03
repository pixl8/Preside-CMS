<!---@feature presideForms--->
<cfscript>
	renderCustomInputField = isTrue( args.includeCustomInputField ?: false );
	fieldValue             = args.fieldValue        ?: {};
	commonFieldConfig      = args.commonFieldConfig ?: {};
</cfscript>

<cfoutput>
	<div class="row">
		<cfif renderCustomInputField>
			<div class="col-md-2">
				#renderFormControl(
					  name           = args.name    ?: ""
					, id             = args.id      ?: ""
					, type           = "textinput"
					, context        = args.context ?: "admin"
					, defaultValue   = "*"
					, savedData      = fieldValue
					, savedDataField = args.name    ?: ""
					, class          = "cron-picker-item cron-item-#args.name#"
					, layout         = "formcontrols.layouts.fieldWithNoLabel"
					, groupClass     = "no-margin-bottom"
				)#
			</div>
		</cfif>

		<div class="#renderCustomInputField ? "col-md-10" : "col-md-12"#">
			#renderFormControl(
					  name               = args.name    ?: ""
					, id                 = args.id      ?: ""
					, type               = "select"
					, context            = args.context ?: "admin"
					, class              = ( renderCustomInputField ? "cron-picker-common-item" : "cron-picker-general-common" )
					, layout             = "formcontrols.layouts.fieldWithNoLabel"
					, groupClass         = "no-margin-bottom"
					, includeEmptyOption = true
					, values             = commonFieldConfig[ args.name ].values ?: ""
					, labels             = commonFieldConfig[ args.name ].labels ?: ""
				)#
		</div>
	</div>
</cfoutput>