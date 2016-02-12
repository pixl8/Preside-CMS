component {

	private string function renderInput( event, rc, prc, args={} ) {

		var name = args.name   ?: "";
		event.include( assetId="/js/frontend/formbuilder/datePicker/" );
		return renderFormControl(
			  argumentCollection = arguments
			, name               = name&"_from"
			, toDate   			 = name&"_to"
			, type               = "DateRangepicker"
			, context            = "formbuilder"
			, fromDateID         = args.id ?: fromDate
			, layout             = ""
			, required           = IsTrue( args.mandatory ?: "" )
			, minDate            = args.minDate ?: ""
			, maxDate            = args.maxDate ?: ""
			, greaterThanCurrentDate        = args.greaterThanCurrentDate 		 ?: ""
			, greaterThanDateEnteredInField = args.greaterThanDateEnteredInField ?: ""
			, lessThanDateEnteredInField    = args.lessThanDateEnteredInField 	 ?: ""
		);
	}

	private any function getItemDataFromRequest( event, rc, prc, args={} ) {
	    var inputName = args.inputName ?: "";
	    var dateFrom  = rc[ inputName & "_from" ] ?: "";
	    var dateTo    = rc[ inputName & "_from" ] ?: "";

	    if ( IsDate( dateFrom ) && IsDate( dateTo ) ) {
	    	return SerializeJson( { from=dateFrom, to=dateTo } );
	    }

	    return "";
	}

	private string function renderResponse( event, rc, prc, args={} ) {
		var response = IsJson( args.response ?: "" ) ? DeserializeJson( args.response ) : {};
		var dateFrom = IsDate( response.from ?: "" ) ? DateFormat( response.from, "yyyy-mm-dd" ) : "";
		var dateTo   = IsDate( response.to   ?: "" ) ? DateFormat( response.to  , "yyyy-mm-dd" ) : "";

		return renderView( view="/formbuilder/item-types/daterange/renderResponse", args={ dateFrom=dateFrom, dateTo=dateTo } );
	}

	private array function renderResponseForExport( event, rc, prc, args={} ) {
		var response = IsJson( args.response ?: "" ) ? DeserializeJson( args.response ) : {};
		var dateFrom = IsDate( response.from ?: "" ) ? DateFormat( response.from, "yyyy-mm-dd" ) : "";
		var dateTo   = IsDate( response.to   ?: "" ) ? DateFormat( response.to  , "yyyy-mm-dd" ) : "";

		return [ dateFrom, dateTo ];
	}

	private array function getExportColumns( event, rc, prc, args={} ) {
		var fieldLabel  = args.label ?: "";
		var fromColumn  = translateResource( uri="formbuilder.item-types.daterange:date.from.column.name", data=[ fieldLabel ]);
		var toColumn    = translateResource( uri="formbuilder.item-types.daterange:date.to.column.name"  , data=[ fieldLabel ]);

		return [ fromColumn, toColumn ];
	}
}