component {
	property name="assetManagerService"      inject="assetManagerService";

	private any function renderResponse( event, rc, prc, args={} ) {
		fileName = listrest (args.response , '_' );
		args.response = event.buildLink(
			fileStorageProvider = 'formBuilderStorageProvider',
			fileStoragePath     = args.response);

		checkDowbloadOption = len(trim(fileName)) ? '<a target="_blank" href="#args.response#"><i class="fa fa-fw fa-download blue"></i> #trim(fileName)#</a>' : translateResource( "cms:datatables.emptyTable" );

		return checkDowbloadOption;
	}

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