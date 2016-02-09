component {
	property name="assetManagerService"      inject="assetManagerService";
	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";
		if ( Len( Trim( args.accept ) ) ) {
			var extensionList = "";
			assetManagerService.expandTypeList( ListToArray( args.accept ) ).each( function( type ){
				extensionList = ListAppend( extensionList, ".#type#" );
			} );
		}
		return renderFormControl(
			  argumentCollection = arguments
			, name               = controlName
			, type               = "fileupload"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
			, accept			 = extensionList ?: ""
		);
	}
}