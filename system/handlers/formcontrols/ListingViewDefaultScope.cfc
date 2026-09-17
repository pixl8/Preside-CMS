/**
 * @feature presideForms and admin
 */
component {

	property name="permissionService" inject="permissionService";
	property name="enumService"       inject="enumService";

	public string function index( event, rc, prc, args={} ) {
		var canShare   = IsTrue( args.canShare ?: ( rc.canShare ?: false ) );
		var userGroups = [];
		var item       = {};

		args.enum  = "listingViewDefaultScope";
		args.items = enumService.listItems( args.enum );

		if ( !args.items.len() ) {
			return "";
		}

		if ( !canShare ) {
			for( item in args.items ) {
				if ( item.id != "individual" ) {
					item.disabled = true;
				}
			}
		} else {
			userGroups = permissionService.listUserGroups(
				  userId          = event.getAdminUserId()
				, includeCatchAll = false
			);
			if ( !ArrayLen( userGroups ) ) {
				for( item in args.items ) {
					if ( item.id == "group" ) {
						item.disabled    = true;
						item.description = translateResource( "preside-objects.admin_datatable_saved_view:field.sharing_scope.disabled.because.no.groups" );
					}
				}
			}
		}

		return renderView( view="formcontrols/enumRadioList/index", args=args );
	}

}
