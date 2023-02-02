component  {

	property name="JSONPrettyPrint" inject="JSONPrettyPrint@JSONPrettyPrint";

	private string function default( event, rc, prc, args={} ){
		return args.data ?: "";
	}

	private string function adminView( event, rc, prc, args={} ){
		return html( argumentCollection=arguments );
	}


	// The "html" context renders JSON as formatted HTML, for use in standard
	// HTML block elements
	private string function html( event, rc, prc, args={} ) {
		var content = args.data ?: "";

		if ( !isJson( content ) ) {
			return content;
		}

		return JSONPrettyPrint.formatJSON(
			  json            = content
			, indent          = "&nbsp;&nbsp;&nbsp;&nbsp;"
			, lineEnding      = "<br>"
			, spaceAfterColon = true
		);
	}

	// The "text" context renders JSON in a plaintext format, for example when
	// displaying in a <pre> block
	private string function text( event, rc, prc, args={} ) {
		var content = args.data ?: "";

		if ( !isJson( content ) ) {
			return content;
		}

		return JSONPrettyPrint.formatJSON(
			  json            = content
			, indent          = "    "
			, lineEnding      = Chr( 10 )
			, spaceAfterColon = true
		);
	}
}