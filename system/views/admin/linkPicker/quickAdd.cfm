<cfscript>
	linkType = rc.type ?: "sitetreelink";

	validLinkTypes = "email,url,sitetreelink";
	if ( !ListFindNoCase( validLinkTypes, linkType ) ) {
		linkType = "sitetreelink";
	}
</cfscript>

<cfoutput>
	<div class="row">
		<div class="col-sm-2">
			<div class="link-type-menu">
				#renderView( view="admin/linkPicker/_linkTypeMenu", args={ selectedType=(rc.type ?: "sitetreelink" ), allowedTypes="sitetreelink,url,email" } )#
			</div>
		</div>
		<div class="col-sm-10">
			<form class="form-horizontal quick-add-form" data-auto-focus-form="true" id="link-picker-form" action="" method="post">
				<input type="hidden" name="type" value="#linkType#" />

				#renderForm(
					  formName  = "form-controls.linkpicker"
					, context   = "admin"
					, formId    = "link-picker-form"
					, savedData = event.getCollectionForForm( "form-controls.linkpicker" )
				)#
			</form>
		</div>
	</div>
</cfoutput>