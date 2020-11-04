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

    private struct function globalRulesEngineFilters( event, rc, prc, args={} ) {
    	return {
    		  filter = "filter_sharing_scope is null or filter_sharing_scope = :filter_sharing_scope"
    		, filterParams = { filter_sharing_scope="global" }
    	};
    }

}