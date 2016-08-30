/**
 * Expression handler for "User's email address matches pattern"
 *
 */
component {

	/**
	 * @expression true
	 * @pattern.placeholder rules.expressions.UserEmailMatch.webrequest:field.pattern.placeholder
	 */
	private boolean function webRequest(
		  required string  pattern
		,          string  _stringOperator = "eq"
		,          boolean _does           = true
	) {
		if ( !isLoggedIn() ) {
			return false;
		}
	}

}