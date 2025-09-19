/**
 * Expression handler for "User has any Webflow instances in some time frame"
 *
 * @expressionContexts user
 * @expressionCategory website_user
 * @feature            rulesEngine and websiteUsers and webflow
 */
component {
	property name="webflowInstanceService" inject="WebflowInstanceService";

	/**
	 * @type.fieldType        enum
	 * @type.enum             webflowSessionType
	 * @type.multiple         false
	 * @webflow.fieldType     webflow
	 * @webflow.multiple      false
	 * @instance.fieldType    webflowInstanceReference
	 * @webflow.multiple      false
	 * @step.fieldType        WebflowStep
	 * @step.multiple         false
	 */
	private boolean function evaluateExpression(
		  required string  type
		, required string  webflow
		,          string  instance  = ""
		,          string  step      = ""
		,          boolean _has      = true
		,          struct  _pastTime = {}
	) {
		var userId = Trim( payload.user.id ?: "" );

		if ( !Len( userId ) ) {
			return false;
		}

		return getPresideObject( "website_user" ).dataExists(
			  filter       = { id=userId }
			, extraFilters = prepareFilters( argumentCollection=arguments )
		);
	}

	/**
	 * @objects    website_user
	 */
	private array function prepareFilters(
		  required string  type
		, required string  webflow
		,          string  instance  = ""
		,          string  step      = ""
		,          boolean _has      = true
		,          struct  _pastTime = {}
		,          string  userField = "website_user.id"
	) {
		return [ webflowInstanceService.prepareInstanceRuleFilter(
			  type        = arguments.type
			, webflowId   = arguments.webflow
			, webflowStep = arguments.step
			, instanceRef = arguments.instance
			, hasValue    = arguments._has
			, timeStruct  = arguments._pastTime
			, userField   = arguments.userField
		) ];
	}
}