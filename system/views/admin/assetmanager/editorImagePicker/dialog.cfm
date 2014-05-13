<cfscript>
	prc.pageTitle    = translateResource( "cms:ckeditor.imagepicker.title" );
	prc.pageSubTitle = translateResource( "cms:ckeditor.imagepicker.subtitle" );
</cfscript>

<cfoutput>
	<cfsavecontent variable="body">
		<h2>TODO, do stuff here</h2>
	</cfsavecontent>
	#renderView( view="/admin/assetmanager/editorImagePicker/_dialogLayout", args={ body=body } )#
</cfoutput>