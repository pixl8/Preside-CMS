component {

	property name="permissionService" inject="permissionService";

	private struct function myAdminGroups( event, rc, prc, args={} ) {
		if ( !event.isAdminUser() ) {
			return { filter="1=0" };
		}

		var groups = permissionService.listUserGroups(
			  userId          = event.getAdminUserId()
			, includeCatchAll = false
		);

		return { filter = { id=groups } };
    }

}