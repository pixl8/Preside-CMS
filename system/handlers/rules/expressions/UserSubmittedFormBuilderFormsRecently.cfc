/**
 * Expression handler for "User has visited any/all of the following pages recently"
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
	 * @days.fieldLabel    rules.expressions.UserVisitedPagesRecently.webrequest:field.days.config.label
	 */
	private boolean function webRequest(
		  required string  forms
		, required numeric days
		,          boolean _has = true
		,          boolean _all = false
	) {
		var userId = payload.user.id ?: "";
		var since  = DateAdd( "d", -days, Now() );

		if ( forms.listLen() > 1 && _all ) {
			for( var fbform in forms.listToArray() ) {
				var result = websiteUserActionService.hasPerformedAction(
					  type        = "formbuilder"
					, action      = "submitform"
					, userId      = userId
					, identifiers = [ fbform ]
					, since       = since
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
				, since       = since
			);
		}

		return _has ? result : !result;
	}

}