/**
 * @feature presideForms
 */
component {
	property name="cronUtil" inject="cronUtil";
	property name="i18n"     inject="i18n";

	private string function index( event, rc, prc, args={} ) {
		var inputName    = args.name         ?: "";
		var defaultValue = args.defaultValue ?: "";
		var value        = rc[ inputName ]   ?: defaultValue;

		if ( !IsSimpleValue( value ) ) {
			value = "";
		}

		args.options = [
			  { field="commonsettings" }
			, { field="dayofweek"     , includeCustomInputField=true }
			, { field="hour"          , includeCustomInputField=true }
			, { field="minute"        , includeCustomInputField=true }
			, { field="second"        , includeCustomInputField=true }
			, { field="dayofmonth"    , includeCustomInputField=true }
			, { field="monthofyear"   , includeCustomInputField=true }
		];

		event.include( "/js/admin/specific/cronPicker/" )
			 .includeData( {
				"cronExpressionReadableEndpoint" = event.buildLink( linkto="formcontrols.cronPicker.parseCronExpression" )
		} );

		return renderView( view="/formControls/cronPicker/index", args=args );
	}

	public string function parseCronExpression( event, rc, prc, args={} ) {
		var expression = rc.expression ?: "";

		if ( !isEmpty( expression ) ) {
			return cronUtil.describeCronTabExression( expression, i18n.getFWLanguageCode() );
		}
		return "";
	}
}