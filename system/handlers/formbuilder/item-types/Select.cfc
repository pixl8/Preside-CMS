component {

	private string function renderInput( event, rc, prc, args={} ) {
		var objectName      = args.datamanagerObject ?: "";
		var formControlArgs = Duplicate( args );

		formControlArgs.context                 = "formbuilder";
		formControlArgs.id                      = args.id ?: ( args.name ?: "" );
		formControlArgs.layout                  = "";
		formControlArgs.required                = IsTrue( args.mandatory ?: "" );
		formControlArgs.multiple                = IsTrue( args.multiple  ?: "" );
		formControlArgs.class                   = "form-control";
		formControlArgs.removeObjectPickerClass = true;

		if( Len( Trim( objectName ) ) ) {
			formControlArgs.object = objectName;
			formControlArgs.type   = "objectPicker";
			formControlArgs.ajax   = false;
		} else {
			formControlArgs.type   = "select";
			formControlArgs.values = ListToArray( args.values, Chr( 10 ) & Chr( 13 ) );
			formControlArgs.labels = ListToArray( args.Labels, Chr( 10 ) & Chr( 13 ) );
		}

		return renderFormControl( argumentCollection = formControlArgs );
	}


	private string function renderResponse( event, rc, prc, args={} ) {
		var responses = ListToArray( args.response ?: "" );
		var itemConfig = args.itemConfiguration    ?: {};

		if ( !IsEmpty( itemConfig.datamanagerObject ?: "" ) ) {
			var objectName = itemConfig.datamanagerObject;

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