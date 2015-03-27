<cfscript>
	record = prc.record ?: {};
	linkType = record.type ?: "sitetreelink";

	validationResult = rc.validationResult ?: "";
	editRecordAction = event.buildAdminLink( linkTo='datamanager.quickEditRecordAction', queryString="object=link" );

	validLinkTypes = "email,url,sitetreelink";
	if ( !ListFindNoCase( validLinkTypes, linkType ) ) {
		linkType = "sitetreelink";
	}

	formId = "link-picker-form";
</cfscript>

<cfoutput>
	<div class="row link-picker">
		<div class="col-sm-2">
			<div class="link-type-menu">
				#renderView( view="admin/linkPicker/_linkTypeMenu", args={ selectedType=linkType, allowedTypes="email,url,sitetreelink,asset" } )#
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