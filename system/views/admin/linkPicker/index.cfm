<cfscript>
	linkType = rc.type ?: "sitetreelink";

	validLinkTypes = "email,url,sitetreelink";
	if ( !ListFindNoCase( validLinkTypes, linkType ) ) {
		linkType = "sitetreelink";
	}

	switch( linkType ) {
		case "email":
			formName = "richeditor.emailLink"
			break;
		case "url":
			formName = "richeditor.plainLink"
			break;
		default:
			formName = "richeditor.sitetreeLink"
	}
</cfscript>

<cfoutput>
	#renderView( view="admin/general/pageTitle", args={
		  title    = translateResource( "cms:linkpicker.title" )
		, subTitle = translateResource( "cms:linkpicker.subTitle" )
		, icon     = "link"
	} )#

	<div class="row">
		<div class="col-sm-3">
			<div class="link-type-menu">
				#renderView( view="admin/linkPicker/_linkTypeMenu", args={ selectedType=(rc.type ?: "sitetreelink" ) } )#
			</div>
		</div>
		<div class="col-sm-9">
			<form class="form-horizontal " data-auto-focus-form="true" id="link-picker-form" action="" method="post">
				<input type="hidden" name="type" value="#linkType#" />

				#renderForm(
					  formName  = formName
					, context   = "richeditor"
					, formId    = "link-picker-form"
					, savedData = event.getCollectionForForm( formName )
				)#
			</form>
		</div>
	</div>
</cfoutput>