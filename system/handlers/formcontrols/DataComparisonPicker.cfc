component {

	variables.operators = {
		  string  = [ "eq", "neq", "contains", "notcontains", "startswith", "notstartswith", "endswith", "notendswith" ]
		, numeric = [ "eq", "neq", "gt", "gte", "lt", "lte" ]
		, array   = [ "anyof", "notanyof", "allof", "noneof" ]
		, boolean = [ "true", "false" ]
	};

	private string function index( event, rc, prc, args={} ) {
		args.dataType = args.dataType ?: "string";

		var inputName    = args.name         ?: "";
		var defaultValue = args.defaultValue ?: "";

		var	value = event.getValue( name=inputName, defaultValue=defaultValue );
		if ( !IsSimpleValue( value ) ) {
			value = "";
		}

		var data = {};
		if ( IsJSON( value ) ) {
			data = DeserializeJSON( value );
		}

		var operatorValues = operators[ args.dataType ] ?: [];
		var operatorLabels = [];

		for ( var operatorValue in operatorValues ){
			ArrayAppend( operatorLabels, translateResource( uri="formcontrols.dataComparisonPicker:operator.#args.dataType#.#operatorValue#" ) );
		}

		args.renderedOperatorFormControl = renderFormControl(
			  name         = "#inputName#_operator"
			, type         = "select"
			, values       = operatorValues
			, labels       = operatorLabels
			, defaultValue = data.operator ?: ""
			, layout       = ""
		);

		args.renderedValueFormControl = args.renderedValueFormControl ?: "";

		if ( isEmptyString( args.renderedValueFormControl ) && !isEmptyString( args.formControl.type ?: "" ) ) {
			args.renderedValueFormControl = renderFormControl(
				  argumentCollection = args.formControl
				, name               = "#inputName#_value"
				, defaultValue       = data.value ?: ""
				, layout             = ""
			);
		}

		args.renderedPropertyFormControl = args.renderedPropertyFormControl ?: "";

		if ( isEmptyString( args.renderedPropertyFormControl ) && !isEmptyString( args.formControl.formControl.type ?: "" ) ) {
			args.renderedPropertyFormControl = renderFormControl(
				  argumentCollection = args.formControl.formControl
				, name               = "#inputName#_property"
				, defaultValue       = data.property ?: ""
				, layout             = ""
			);
		}

		event.include( "/js/admin/specific/dataComparisonPicker/"  )
			 .include( "/css/admin/specific/dataComparisonPicker/"  );

		return renderView( view="/formControls/dataComparisonPicker/index", args=args );
	}

}