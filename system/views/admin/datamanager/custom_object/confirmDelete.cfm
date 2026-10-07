<!---@feature admin and customObjects--->
<cfscript>
	objectLabel   = prc.objectLabel   ?: "";
	recordCount   = Val( prc.recordCount ?: 0 );
	fieldCount    = Val( prc.fieldCount  ?: 0 );
	deleteAction  = prc.deleteAction  ?: "";
	formName      = prc.formName      ?: "preside-objects.custom_object.admin.delete.confirm";
	actionButtons = prc.actionButtons ?: [];
	encodedLabel  = EncodeForHtml( objectLabel );
	formId        = "deleteCustomObjectForm-" & CreateUUId();
	recordMessage = "";
	fieldMessage  = "";

	if ( recordCount == 1 ) {
		recordMessage = translateResource( uri="preside-objects.custom_object:delete.records.one" );
	} else if ( recordCount > 1 ) {
		recordMessage = translateResource( uri="preside-objects.custom_object:delete.records.many", data=[ recordCount ] );
	} else {
		recordMessage = translateResource( uri="preside-objects.custom_object:delete.records.empty" );
	}

	if ( fieldCount == 1 ) {
		fieldMessage = translateResource( uri="preside-objects.custom_object:delete.fields.one" );
	} else if ( fieldCount > 1 ) {
		fieldMessage = translateResource( uri="preside-objects.custom_object:delete.fields.many", data=[ fieldCount ] );
	} else {
		fieldMessage = translateResource( uri="preside-objects.custom_object:delete.fields.empty" );
	}
</cfscript>
<cfoutput>
	<div class="alert alert-danger">
		<p>
			<i class="fa fa-fw fa-exclamation-triangle"></i>
			#translateResource( uri="preside-objects.custom_object:delete.warning", data=[ encodedLabel ] )#
		</p>
		<p>#recordMessage#</p>
		<p>#fieldMessage#</p>
	</div>

	<form id="#formId#" data-auto-focus-form="true" data-prevent-multiple-submit="true" class="form-horizontal" method="post" action="#deleteAction#">
		#renderForm(
			  formName         = formName
			, context          = "admin"
			, formId           = formId
			, savedData        = {}
			, validationResult = rc.validationResult ?: ""
			, additionalArgs   = { fields={ confirmation_name={ placeholder=translateResource( uri="preside-objects.custom_object:delete.confirm.help", data=[ objectLabel ] ) } } }
		)#

		<div class="form-actions row">
			#renderView( view="/admin/datamanager/_addOrEditRecordActionButtons", args={ actionButtons=actionButtons } )#
		</div>
	</form>
</cfoutput>
