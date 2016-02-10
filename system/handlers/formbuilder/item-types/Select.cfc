component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName 						= args.name 			 ?: "";
		var dataManagerName 					= args.dataManager 		 ?: "";

		formControl.name            			= controlName;
		formControl.context         			= "formbuilder";
		formControl.id              			= args.id 				 ?: controlName;
		formControl.layout          			= "";
		formControl.required        			= IsTrue( args.mandatory ?: "" );
		formControl.multiple 					= args.multiple 		 ?: 0;
		formControl.class 						= "form-control";;
		formControl.removeObjectPickerClass 	= true;

		if( len( dataManagerName ) ) {
			formControl.object 					= dataManagerName;
			formControl.type        			= "objectPicker";
			formControl.ajax 					= false;
		} else {
			formControl.type        			= "select";
			formControl.values 					= replaceNoCase( args.values, chr( 10 ), ',', 'All' ); // chr ( 10 ) means newline
			formControl.labels					= replaceNoCase( args.Labels, chr( 10 ), ',', 'All' )		 ?: "";
		}

		return renderFormControl( argumentCollection = formControl );
	}


	private string function renderResponse( event, rc, prc, args={} ) {
		var responses = ListToArray( args.response ?: "" );
		var itemConfig = args.itemConfiguration    ?: {};

		if ( !IsEmpty( itemConfig.dataManager ?: "" ) ) {
			var objectName = itemConfig.dataManager;

			for( var i=1; i<=responses.len(); i++ ) {
				responses[ i ] = renderLabel( objectName=objectName, recordId=responses[ i ] );
			}
		} else {
			var labels = ListToArray( itemConfig.labels ?: "", Chr(10) & Chr(13) );
			var values = ListToArray( itemConfig.values ?: "", Chr(10) & Chr(13) );

			for( var i=1; i<=responses.len(); i++ ) {
				var index = values.findNoCase( responses[i] );
				if ( index && labels.len() >= index ) {
					responses[ i ] = labels[ index ];
				}
			}
		}

		return responses.toList( args.delim ?: "<br>" );
	}

	private array function renderResponseForExport( event, rc, prc, args={} ) {
		args.delim = ", ";
		return [ renderResponse( argumentCollection=arguments ) ];
	}
}