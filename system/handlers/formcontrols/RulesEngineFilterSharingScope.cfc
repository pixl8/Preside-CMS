component {

	property name="rulesEngineFilterService" inject="rulesEngineFilterService";
	property name="permissionService"        inject="permissionService";
	property name="enumService"              inject="enumService";

	public string function index( event, rc, prc, args={} ) {
		args.enum  = "rulesfilterScopeAll";
		args.items = enumService.listItems( args.enum );

		if ( !args.items.len() ) {
		    return "";
		}

		var isUsed = false;
		if ( Len( prc.record.id ?: "" ) ) {
			if ( rulesEngineFilterService.filterIsUsed( prc.record.id ) ) {
				isUsed = true;
				for( var item in args.items ) {
					if ( item.id != "global" and item.id != ( args.defaultValue ?: "" ) ) {
						item.disabled    = true;
						item.description = translateResource( "preside-objects.rules_engine_condition:field.filter_sharing_scope.disabled.because.used" );
					}
				}
			}
		}

		if ( !isUsed ) {
			var userGroups = permissionService.listUserGroups(
				  userId          = event.getAdminUserId()
				, includeCatchAll = false
			);
			if ( !ArrayLen( userGroups ) ) {
				for( var item in args.items ) {
					if ( item.id == "group" ) {
						item.disabled    = true;
						item.description = translateResource( "preside-objects.rules_engine_condition:field.filter_sharing_scope.disabled.because.no.groups" );
					}
				}
			}

		}



		return renderView( view="formcontrols/enumRadioList/index", args=args );
	}

}