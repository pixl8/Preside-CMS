/**
 * Expression handler for "User has visited any/all of the following pages"
 *
 * @feature websiteUsers
 */
component {

	property name="websiteUserActionService" inject="websiteUserActionService";

	/**
	 * @expression         true
	 * @expressionContexts webrequest,user
	 * @forms.fieldType    object
	 * @forms.object       formbuilder_form
	 */
	private boolean function webRequest(
		  required string  forms
		,          boolean _has = true
		,          boolean _all = false
	) {
		var userId = payload.user.id ?: "";

		if ( forms.listLen() > 1 && _all ) {
			for( var fbform in forms.listToArray() ) {
				var result = websiteUserActionService.hasPerformedAction(
					  type        = "formbuilder"
					, action      = "submitform"
					, userId      = userId
					, identifiers = [ fbform ]
				);

				if ( result != _has ) {
					return false;
				}
			}

			return true;
		} else {
			var result = websiteUserActionService.hasPerformedAction(
				  type        = "formbuilder"
				, action      = "submitform"
				, userId      = userId
				, identifiers = ListToArray( forms )
			);
		}

		return _has ? result : !result;
	}

}