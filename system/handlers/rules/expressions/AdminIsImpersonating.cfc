/**
 * Expression handler for "Admin is/is not impersonating"
 * 
 * @expressionCategory website_user
 * @feature            rulesEngine and websiteUsers and admin
 */
component {
	
	private boolean function evaluateExpression( boolean _is = true ) {
		var isImpersonating = event.isWebUserImpersonated();

		return arguments._is ? isImpersonating : !isImpersonating;
	}

}
