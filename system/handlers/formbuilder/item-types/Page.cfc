/**
 * @feature formBuilder
 */
component {

	private string function renderAdminPlaceholder( event, rc, prc, args={} ) {
		var label = args.type.title ?: "";

		if ( !isEmptyString( args.configuration.label ?: "" ) ) {
			label = args.configuration.label;
		}

		if ( !isEmptyString( args.configuration.condition ?: "" ) ) {
			label &= ' <span>(<i class="fa fa-fw fa-map-signs"></i>&nbsp;' & renderlabel( objectName="rules_engine_condition", recordId=args.configuration.condition ) & ")</span>";
		}

		return label;
	}

}