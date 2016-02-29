component {
	property name="assetManagerService" inject="assetManagerService";

	private any function renderResponse( event, rc, prc, args={} ) {
		var fileName = Listlast( args.response, '/\' );

		if ( Len( Trim( fileName ) ) ) {
			var downloadLink = event.buildLink(
				  fileStorageProvider = 'formBuilderStorageProvider'
				, fileStoragePath     = args.response
			);

			return '<a target="_blank" href="#downloadLink#"><i class="fa fa-fw fa-download blue"></i> #Trim( fileName )#</a>';
		}

		return translateResource( "formbuilder.item-types.fileupload:render.empty.response" );
	}

	private string function renderInput( event, rc, prc, args={} ) {
		var accept = "";

		if ( Len( Trim( args.accept ?: "" ) ) ) {
			assetManagerService.expandTypeList( ListToArray( args.accept ) ).each( function( type ){
				accept = ListAppend( accept, ".#type#" );
			} );
		}

		return renderFormControl(
			  argumentCollection = args
			, type               = "fileupload"
			, context            = "formbuilder"
			, id                 = args.id ?: ( args.name ?: "" )
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
			, accept             = accept
			, maximumFileSize    = Val( args.maximumFileSize ?: 0 )
		);
	}

	private array function getValidationRules( event, rc, prc, args={} ) {
		var rules = [];

		if ( Val( args.maximumFileSize ?: "" ) ) {
			rules.append( {
				  fieldname = args.name ?: ""
				, validator = "fileSize"
				, params    = { field ="#args.maximumFileSize#" }
			} );
		}

		return rules;
	}
}