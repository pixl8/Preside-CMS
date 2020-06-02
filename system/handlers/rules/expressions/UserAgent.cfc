/**
 * Expression handler for "User-agent matches" expression
 *
 * @expressionCategory browser
 * @expressionContexts webrequest
 */
component {

	private boolean function evaluateExpression(
		  string  value           = ""
		, string  _stringOperator = "contains"
	) {
		var userAgent = cgi.http_user_agent ?: "";

		switch ( arguments._stringOperator ) {
			case "eq"            : return userAgent == arguments.value;
			case "neq"           : return userAgent != arguments.value;
			case "contains"      : return userAgent.findNoCase( arguments.value ) > 0;
			case "notcontains"   : return userAgent.findNoCase( arguments.value ) == 0;
			case "startsWith"    : return userAgent.left( Len( arguments.value ) ) == arguments.value;
			case "notstartsWith" : return userAgent.left( Len( arguments.value ) ) != arguments.value;
			case "endsWith"      : return userAgent.right( Len( arguments.value ) ) == arguments.value;
			case "notendsWith"   : return userAgent.right( Len( arguments.value ) ) != arguments.value;
		}
	}

}