/**
 * Handler for rules engine 'time period type'
 *
 */
component {

	property name="presideObjectService" inject="presideObjectService";
	property name="timePeriodService"    inject="rulesEngineTimePeriodService";

	private string function renderConfiguredField( string value="", struct config={} ) {
		var timePeriod = {};
		var data       = [];
		var type       = "alltime"

		try {
			timePeriod = DeserializeJson( arguments.value );
		} catch( any e ){
			timePeriod = { type="alltime" };
		};

		switch( timePeriod.type ?: "alltime" ){
			case "between":
				type = timePeriod.type;
				data = [ timePeriod.date1 ?: "", timePeriod.date2 ?: "" ];
			break;
			case "since":
			case "before":
			case "until":
			case "after":
				type = timePeriod.type;
				data = [ timePeriod.date1 ?: "" ];
			break;
			case "recent":
			case "upcoming":
			case "pastminus":
			case "futureplus":
				type = timePeriod.type;
				data = [
					  NumberFormat( Val( timePeriod.measure ?: "" ) )
					, translateResource( "cms:time.period.unit.#( timePeriod.unit ?: 'd' )#" )
				];
			break;
			case "future":
			case "past":
			case "yesterday":
			case "today":
			case "tomorrow":
			case "lastweek":
			case "thisweek":
			case "nextweek":
			case "lastmonth":
			case "thismonth":
			case "nextmonth":
				type = timePeriod.type;
			break;
			default:
				type = "alltime";
		}

		return translateResource( uri="cms:rulesEngine.time.period.type.#type#.configured", data=data );
	}

	private string function renderConfigScreen( string value="", struct config={} ) {
		rc.delete( "value" );

		return renderFormControl(
			  name         = "value"
			, type         = "timePeriodPicker"
			, pastOnly     = IsTrue( config.pastOnly ?: "" )
			, futureOnly   = IsTrue( config.futureOnly ?: "" )
			, label        = translateResource( config.fieldLabel ?: "cms:rulesEngine.fieldtype.timePeriod.config.label" )
			, savedValue   = arguments.value
			, defaultValue = arguments.value
			, required     = true
		);
	}

	private struct function prepareConfiguredFieldData( string value="", struct config={} ) {
		return timePeriodService.convertTimePeriodToDateRange( arguments.value );
	}

}