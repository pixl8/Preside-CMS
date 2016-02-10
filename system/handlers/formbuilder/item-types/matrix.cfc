component {

	private string function renderInput( event, rc, prc, args={} ) {
		var controlName = args.name ?: "";

		return renderFormControl(
			  argumentCollection = arguments
			, name               = controlName
			, type               = "matrix"
			, context            = "formbuilder"
			, id                 = args.id ?: controlName
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
			, rows               = replaceNoCase( args.rows, chr( 10 ), ',', 'All' )	?: "" // chr ( 10 ) means newline
			, columns			 = replaceNoCase( args.columns, chr( 10 ), ',', 'All' )	?: ""
			, options			 = args.option ?: ""
		);
	}

	private any function getItemDataFromRequest( event, rc, prc, args={} ) {
	    var inputName = args.inputName ?: "";
	    var returnData = "";

	    for ( key in rc ){
	    	if ( findNoCase( inputName, key ) ){
	    		name = replaceNoCase( key, inputName&"_", "", "All" );
	    		returnData = listAppend( returnData, name&" - "&rc[ inputName & "_" &name ] );
	    	}
	    }
	    return returnData;
	}
}