/**
 * @feature presideForms and admin
 */
component {

	property name="permissionService" inject="permissionService";
	property name="enumService"       inject="enumService";

	public string function index( event, rc, prc, args={} ) {
		args.enum  = "listingViewSharingScope";
		args.items = enumService.listItems( args.enum );

		if ( !args.items.len() ) {
			return "";
		}

		var userGroups = permissionService.listUserGroups(
			  userId          = event.getAdminUserId()
			, includeCatchAll = false
		);
		if ( !ArrayLen( userGroups ) ) {
			for( var item in args.items ) {
				if ( item.id == "group" ) {
					item.disabled    = true;
					item.description = translateResource( "preside-objects.admin_datatable_saved_view:field.sharing_scope.disabled.because.no.groups" );
				}
			}
		}

		return renderView( view="formcontrols/enumRadioList/index", args=args );
	}

}
