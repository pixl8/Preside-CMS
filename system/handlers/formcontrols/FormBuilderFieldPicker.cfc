component {

	property name="formBuilderService" inject="formBuilderService";

	public string function index( event, rc, prc, args={} ) {
		var formId    = args.formId ?: ( rc[ args.formIdField ?: "" ] ?: ( rc.formId ?: ( rc.id ?: "" ) ) );
		var itemTypes = ( args.itemTypes ?: "" ).listToArray();
		var items     = formBuilderService.getFormItems(
			  id        = formId
			, itemTypes = itemTypes
		);

		if ( !items.Len() ) {
			return "";
		}

		args.values = [ "" ];
		args.labels = [ "" ];
		for( var item in items ) {
			args.values.append( item.id );
			args.labels.append( item.configuration.label ?: item.id );
		}

		return renderView( view="formcontrols/select/index", args=args );
	}
}