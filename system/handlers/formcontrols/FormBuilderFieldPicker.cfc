component {

	property name="formBuilderService" inject="formBuilderService";

	public string function index( event, rc, prc, args={} ) {
		var formId    = args.formId ?: ( rc[ args.formIdField ?: "" ] ?: ( rc.formId ?: ( rc.id ?: "" ) ) );
		var itemTypes = ( args.itemTypes ?: "" ).listToArray();
		var items     = formBuilderService.getFormItems(
			  id        = formId
			, itemTypes = itemTypes
		);
		
		args.values = [ "" ];
		args.labels = [ "" ];

		for( var item in items ) {
			args.values.append( item.id );
			args.labels.append( item.configuration.label ?: item.id );
		}
		
		if ( !items.Len() ) {
			return '#renderView( view="formcontrols/select/index", args=args )#<p class="alert alert-warning">' & translateResource( "formbuilder.actions.anonymousCustomerEmail:field.no.emailField.for.selection" ) & '</p>';
		}else {
			return renderView( view="formcontrols/select/index", args=args );
		}
	}
}