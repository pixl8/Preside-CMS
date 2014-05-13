<cfscript>
	prc.pageTitle    = translateResource( "cms:ckeditor.imagepicker.image.saved" );
	prc.pageSubTitle = translateResource( "cms:ckeditor.imagepicker.image.saved.subtitle" );
</cfscript>

<cfoutput>
	#renderView( view="/admin/assetmanager/editorImagePicker/_dialogLayout", args={ body=translateResource( "cms:ckeditor.imagepicker.image.saved.message" ) } )#
</cfoutput>