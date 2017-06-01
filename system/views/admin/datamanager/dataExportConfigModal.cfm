<cfparam name="args.objectName" />
<cfparam name="args.defaultExportFilename" />

<cfoutput>
	<form class="form-horizontal export-config-form" data-auto-focus-form="true" method="post" action="" id="export-config-form-#args.objectName#">
		#renderForm(
			  formName       = "dataExport.exportConfiguration"
			, context        = "admin"
			, formId         = "export-config-form-#args.objectName#"
			, savedData      = { filename=args.defaultExportFilename }
			, additionalArgs = { fields={ exportFields={ exportObject=args.objectName } } }
		)#
	</form>
</cfoutput>