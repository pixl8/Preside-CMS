/**
 * Rules expression handler for "User (is/is not) a member of (any/all/none) of the groups (groups)"
 * Defines two contexts: user (logged in user/user in general) and event_booking (user who made a booking)
 *
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
	 * @expressionContexts user,marketing
	 * @expression         true
	 *
	 */
	private boolean function user(
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


	/**
	 * Rules engine expression for checking whether
	 * or not the event booking user belongs (or not) to the
	 * configured user group(s).
	 * \n
	 * Expression appears like: "Booking user {_is} a member of {_any} of the groups {groups}"
	 *
	 * @groups.fieldType  object
	 * @groups.object     user_group
	 * @expression
	 *
	 */
	private boolean function global(
		  required struct  payload
		, required any     groups
		, required boolean _is
		, required string  _any
	) {
		var isMember = userService.userBelongsToGroups(
			  userId = argument.payload.event_booking.booked_by_user ?: ""
			, groups = arguments.groups
			, scope  = arguments._any // all / any / none
		);

		return arguments._is ? isMember : !isMember
	}


	private any function helperMethod() {

	}
}