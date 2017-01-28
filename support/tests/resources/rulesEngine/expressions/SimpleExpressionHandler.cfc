/**
 * Rules expression handler for "User (is/is not) a member of (any/all/none) of the groups (groups)"
 * Defines two contexts: user (logged in user/user in general) and event_booking (user who made a booking)
 *
 * @feature myfeature
 * @expressionContexts user,marketing
 */
component {

	property name="userService" inject="userService";

	/**
	 * Rules engine expression for checking whether
	 * or not the current user belongs (or not) to the
	 * configured user group(s).
	 * \n
	 * Expression appears like: "User {_is} a member of {_any} of the groups {groups}"
	 *
	 * @groups.fieldType   object
	 * @groups.object      user_group
	 *
	 */
	private boolean function evaluateExpression(
		  required struct  payload
		, required any     groups
		, required boolean _is
		, required string  _any
	) {
		var isMember = userService.userBelongsToGroups(
			  userId = arguments.payload.user.id ?: ""
			, groups = arguments.groups
			, scope  = arguments._any // all / any / none
		);

		return arguments._is ? isMember : !isMember
	}

}