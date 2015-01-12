<cfscript>
	linkType = rc.type ?: "sitetreelink";

	validLinkTypes = "email,url,sitetreelink";
	if ( !ListFindNoCase( validLinkTypes, linkType ) ) {
		linkType = "sitetreelink";
	}

	formId = "link-picker-form";

	addRecordAction = event.buildAdminLink( linkTo='datamanager.quickAddRecordAction', queryString="object=link" );
	validationResult = rc.validationResult ?: "";
</cfscript>

<cfoutput>
	<div class="row link-picker">
		<div class="col-sm-2">
			<div class="link-type-menu">
				#renderView( view="admin/linkPicker/_linkTypeMenu", args={ selectedType=(rc.type ?: "sitetreelink" ), allowedTypes="email,url,sitetreelink,asset" } )#
			</div>
		</div>
		<div class="col-sm-10">
			<form id="#formId#" data-auto-focus-form="true" data-dirty-form="protect" class="form-horizontal quick-add-form" method="post" action="#addRecordAction#">
				#renderForm(
					  formName         = "preside-objects.link.admin.quickadd"
					, context          = "admin"
					, formId           = formId
					, validationResult = validationResult
				)#
			</form>
		</div>
	</div>
</cfoutput>