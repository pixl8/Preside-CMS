<cfscript>
	linkType = rc.type ?: "sitetreelink";

	validLinkTypes = "email,url,sitetreelink";
	if ( !ListFindNoCase( validLinkTypes, linkType ) ) {
		linkType = "sitetreelink";
	}
</cfscript>

<cfoutput>
	#renderView( view="admin/general/pageTitle", args={
		  title    = translateResource( "cms:linkpicker.title" )
		, subTitle = translateResource( "cms:linkpicker.subTitle" )
		, icon     = "link"
	} )#

	<div class="row">
		<div class="col-sm-2">
			<div class="link-type-menu">
				#renderView( view="admin/linkPicker/_linkTypeMenu", args={ selectedType=(rc.type ?: "sitetreelink" ) } )#
			</div>
		</div>
		<div class="col-sm-10">
			<form class="form-horizontal " data-auto-focus-form="true" id="link-picker-form" action="" method="post">
				<input type="hidden" name="type" value="#linkType#" />

				#renderForm(
					  formName  = "richeditor.link"
					, context   = "richeditor"
					, formId    = "link-picker-form"
					, savedData = event.getCollectionForForm( "richeditor.link" )
				)#
			</form>
		</div>
	</div>
</cfoutput>