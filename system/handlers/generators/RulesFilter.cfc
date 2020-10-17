/**
 * Value generator helpers for rules engine filters
 *
 */
component {

	private string function owner( event, rc, prc, args={} ) {
		var scope  = Trim( args.data.filter_sharing_scope ?: "" );
		var groups = Trim( args.data.user_groups ?: "" );

		if ( !Len( scope ) ) {
			return;
		}

		var isPrivateFilter = ArrayFindNoCase( [ "group", "individual" ], scope );

		if ( isPrivateFilter || Len( groups ) ) {
			return event.getAdminUserId();
		}

		return "";
	}

	private any function allowGroupEdit( event, rc, prc, args={} ) {
		var scope  = Trim( args.data.filter_sharing_scope ?: "" );
		var groups = Trim( args.data.user_groups ?: "" );

		if ( !Len( scope ) ) {
			return;
		}

		var isPrivateFilter = ArrayFindNoCase( [ "group", "individual" ], scope );

		return !isPrivateFilter && !Len( groups );
	}


}