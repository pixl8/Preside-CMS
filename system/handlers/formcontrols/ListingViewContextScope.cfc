/**
 * @feature presideForms and admin
 */
component {

	public string function index( event, rc, prc, args={} ) {
		var contextLabel = Trim( args.listingContextLabel ?: ( rc.listingContextLabel ?: "" ) );

		if ( !Len( contextLabel ) ) {
			return "";
		}

		args.items = [{
			  id          = "this"
			, label       = translateResource( uri="preside-objects.admin_datatable_saved_view:field.context_scope.this.label", data=[ contextLabel ], defaultValue=contextLabel )
			, description = translateResource( uri="preside-objects.admin_datatable_saved_view:field.context_scope.this.description" )
			, iconClass   = "fa-filter"
		},{
			  id          = "global"
			, label       = translateResource( uri="preside-objects.admin_datatable_saved_view:field.context_scope.global.label" )
			, description = translateResource( uri="preside-objects.admin_datatable_saved_view:field.context_scope.global.description" )
			, iconClass   = "fa-th"
		}];

		if ( !Len( Trim( args.defaultValue ?: "" ) ) ) {
			args.defaultValue = "this";
		}

		return renderView( view="formcontrols/enumRadioList/index", args=args );
	}

}
