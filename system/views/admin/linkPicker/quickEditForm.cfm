<cfscript>
	record    = prc.record    ?: {};
	linkTypes = prc.linkTypes ?: [];
	linkType  = record.type   ?: ( linkTypes[ 1 ] ?: "sitetreelink" );

	formId = "link-picker-form";

	validationResult = rc.validationResult ?: "";
	editRecordAction = event.buildAdminLink( linkTo='datamanager.quickEditRecordAction', queryString="object=link" );
</cfscript>

<cfoutput>
	<div class="row link-picker">
		<div class="col-sm-2">
			<div class="link-type-menu">
				#renderView( view="admin/linkPicker/_linkTypeMenu", args={ selectedType=linkType, allowedTypes=linkTypes } )#
			</div>
		</div>
		<div class="col-sm-10">
			<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal quick-edit-form" method="post" action="#editRecordAction#">
				<input name="id" type="hidden" value="#( rc.id ?: '' )#" />

				#renderForm(
					  formName         = "preside-objects.link.admin.quickedit"
					, context          = "admin"
					, formId           = formId
					, validationResult = validationResult
					, savedData        = record
				)#
			</form>
		</div>
	</div>
</cfoutput>