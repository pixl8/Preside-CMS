/**
 * Expression handler for "Referer matches" expression
 *
 * @expressionCategory browser
 * @expressionContexts webrequest
 */
component {

	/**
	 * @urlpart.fieldtype enum
	 * @urlpart.enum      urlStringPart
	 * @urlpart.multiple  false
	 *
	 */
	private boolean function evaluateExpression(
		  string  value           = ""
		, string  urlpart         = "url"
		, string  _stringOperator = "contains"
	) {
		var stringToMatch = cgi.http_referer ?: "";

		switch( arguments.urlpart ) {
			case "domain":
				stringToMatch = stringToMatch.reReplaceNoCase( "^.*?:\/\/(.*?)(\/.*)?$", "\1" );
			break;
			case "path":
				stringToMatch = stringToMatch.reReplaceNoCase( "^.*?:\/\/(.*?)(\/.*?)(\?.*)?$", "\2" );
			break;
			case "querystring":
				stringToMatch = stringToMatch.reReplaceNoCase( "^.*?:\/\/(.*?)(\/.*?)(\?(.*))?", "\4" );
			break;
			case "protocol":
				stringToMatch = stringToMatch.reReplaceNoCase( "^(.*?):\/\/.*$", "\1" );
			break;
		}

		switch ( arguments._stringOperator ) {
			case "eq"            : return stringToMatch == arguments.value;
			case "neq"           : return stringToMatch != arguments.value;
			case "contains"      : return stringToMatch.findNoCase( arguments.value ) > 0;
			case "notcontains"   : return stringToMatch.findNoCase( arguments.value ) == 0;
			case "startsWith"    : return stringToMatch.left( Len( arguments.value ) ) == arguments.value;
			case "notstartsWith" : return stringToMatch.left( Len( arguments.value ) ) != arguments.value;
			case "endsWith"      : return stringToMatch.right( Len( arguments.value ) ) == arguments.value;
			case "notendsWith"   : return stringToMatch.right( Len( arguments.value ) ) != arguments.value;
		}
	}

}