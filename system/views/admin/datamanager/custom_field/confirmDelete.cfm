<!---@feature admin and customFields--->
<cfscript>
	fieldName        = prc.fieldName        ?: "";
	objectTitle      = prc.objectTitle      ?: "";
	storesValues     = IsTrue( prc.storesValues ?: "" );
	storedValueCount = Val( prc.storedValueCount ?: 0 );
	versioned        = IsTrue( prc.versioned ?: "" );
	deleteAction     = prc.deleteAction     ?: "";
	formName         = prc.formName         ?: "preside-objects.custom_field.admin.delete.confirm";
	actionButtons    = prc.actionButtons    ?: [];
	encodedName      = EncodeForHtml( fieldName );
	encodedObject    = EncodeForHtml( objectTitle );
	formId           = "deleteCustomFieldForm-" & CreateUUId();
	storedMessage    = "";

	if ( storesValues && storedValueCount == 1 ) {
		storedMessage = translateResource( uri="preside-objects.custom_field:delete.stored.one" );
	} else if ( storesValues && storedValueCount > 1 ) {
		storedMessage = translateResource( uri="preside-objects.custom_field:delete.stored.many", data=[ storedValueCount ] );
	} else if ( storesValues ) {
		storedMessage = translateResource( uri="preside-objects.custom_field:delete.stored.empty" );
	} else {
		storedMessage = translateResource( uri="preside-objects.custom_field:delete.notstored" );
	}
</cfscript>
<cfoutput>
	<div class="alert alert-danger">
		<p>
			<i class="fa fa-fw fa-exclamation-triangle"></i>
			#translateResource( uri="preside-objects.custom_field:delete.warning", data=[ encodedName, encodedObject ] )#
		</p>
		<p>#storedMessage#</p>
		<cfif storesValues && storedValueCount && versioned>
			<p>#translateResource( uri="preside-objects.custom_field:delete.stored.versions" )#</p>
		</cfif>
	</div>

	<form id="#formId#" data-auto-focus-form="true" data-prevent-multiple-submit="true" class="form-horizontal" method="post" action="#deleteAction#">
		#renderForm(
			  formName         = formName
			, context          = "admin"
			, formId           = formId
			, savedData        = {}
			, validationResult = rc.validationResult ?: ""
			, additionalArgs   = { fields={ confirmation_name={ placeholder=translateResource( uri="preside-objects.custom_field:delete.confirm.help", data=[ fieldName ] ) } } }
		)#

		<div class="form-actions row">
			#renderView( view="/admin/datamanager/_addOrEditRecordActionButtons", args={ actionButtons=actionButtons } )#
		</div>
	</form>
</cfoutput>
