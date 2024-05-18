/**
 * @feature presideForms
 */
component {
	private string function index( event, rc, prc, args={} ) {
		var inputName    = args.name         ?: "";
		var defaultValue = args.defaultValue ?: "";
		var value        = rc[ inputName ]   ?: defaultValue;

		if ( !IsSimpleValue( value ) ) {
			value = "";
		}

		args.commonFieldConfig = {
			  commonsettings = _getCommonSettingsCommonFieldConfig()
			, dayofweek      = _getDayOfWeekCommonFieldConfig()
			, hour           = _getHourCommonFieldConfig()
			, minute         = _getMinuteCommonFieldConfig()
			, second         = _getSecondCommonFieldConfig()
			, dayofmonth     = _getDayOfMonthCommonFieldConfig()
			, monthofyear    = _getMonthOfYearCommonFieldConfig()
		};

		return renderView( view="/formControls/cronPicker/_item", args=args );
	}

	private struct function _getCommonSettingsCommonFieldConfig( event, rc, prc, args={} ) {
		var outputValues = "";
		var outputLabels = "";

		outputValues = listAppend( outputValues, "disabled" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:commonsettings.disabled.label" ) );

		outputValues = listAppend( outputValues, "0 * * * * *" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:commonsettings.onceperminute.label" ) );

		outputValues = listAppend( outputValues, "0 */5 * * * *" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:commonsettings.oncePerFiveMinute.label" ) );

		outputValues = listAppend( outputValues, "0 */30 * * * *" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:commonsettings.twicePerHour.label" ) );

		outputValues = listAppend( outputValues, "0 0 * * * *" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:commonsettings.oncePerHour.label" ) );

		outputValues = listAppend( outputValues, "0 0 0 * * *" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:commonsettings.oncePerDay.label" ) );

		outputValues = listAppend( outputValues, "0 0 0 */7 * 0" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:commonsettings.oncePerWeek.label" ) );

		outputValues = listAppend( outputValues, "0 0 0 1 * *" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:commonsettings.oncePerMonth.label" ) );

		outputValues = listAppend( outputValues, "0 0 0 1 1 1" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:commonsettings.oncePerYear.label" ) );

		return { values=outputValues, labels=outputLabels};
	}

	private struct function _getDayOfWeekCommonFieldConfig( event, rc, prc, args={} ) {
		var outputValues = "";
		var outputLabels = "";

		outputValues = listAppend( outputValues, "*" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:dayOfWeek.everyDay.label" ) );

		outputValues = listAppend( outputValues, "1-5" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:dayOfWeek.everyWeekday.label" ) );

		outputValues = listAppend( outputValues, "6-7" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:dayOfWeek.everyWeekendDay.label" ) );

		return { values=outputValues, labels=outputLabels };
	}
	private struct function _getHourCommonFieldConfig( event, rc, prc, args={} ) {
		var outputValues = "";
		var outputLabels = "";

		outputValues = listAppend( outputValues, "*" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:hour.everyHour.label" ) );

		outputValues = listAppend( outputValues, "*/2" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:hour.everyOtherHour.label" ) );

		outputValues = listAppend( outputValues, "*/3" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:hour.everyThirdHour.label" ) );

		outputValues = listAppend( outputValues, "*/4" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:hour.everyFourthHour.label" ) );

		outputValues = listAppend( outputValues, "*/6" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:hour.everySixthHour.label" ) );

		outputValues = listAppend( outputValues, "*/12" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:hour.everyTwelveHour.label" ) );

		return { values=outputValues, labels=outputLabels };
	}
	private struct function _getMinuteCommonFieldConfig( event, rc, prc, args={} ) {
		var outputValues = "";
		var outputLabels = "";

		outputValues = listAppend( outputValues, "*" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:minute.oncePerMinute.label" ) );

		outputValues = listAppend( outputValues, "*/2" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:minute.oncePerTwoMinute.label" ) );

		outputValues = listAppend( outputValues, "*/5" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:minute.oncePerFiveMinute.label" ) );

		outputValues = listAppend( outputValues, "*/10" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:minute.oncePerTenMinute.label" ) );

		outputValues = listAppend( outputValues, "*/15" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:minute.oncePerFifteenMinute.label" ) );

		outputValues = listAppend( outputValues, "*/30" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:minute.oncePerThirtyMinute.label" ) );

		return { values=outputValues, labels=outputLabels };
	}
	private struct function _getSecondCommonFieldConfig( event, rc, prc, args={} ) {
		var outputValues = "";
		var outputLabels = "";

		outputValues = listAppend( outputValues, "*/15" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:second.oncePerFifteenSecond.label" ) );

		outputValues = listAppend( outputValues, "*/30" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:second.oncePerThirtySecond.label" ) );

		return { values=outputValues, labels=outputLabels };
	}
	private struct function _getDayOfMonthCommonFieldConfig( event, rc, prc, args={} ) {
		var outputValues = "";
		var outputLabels = "";

		outputValues = listAppend( outputValues, "*" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:dayOfMonth.everyDay.label" ) );

		outputValues = listAppend( outputValues, "*/2" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:dayOfMonth.everyOtherDay.label" ) );

		return { values=outputValues, labels=outputLabels };
	}
	private struct function _getMonthOfYearCommonFieldConfig( event, rc, prc, args={} ) {
		var outputValues = "";
		var outputLabels = "";

		outputValues = listAppend( outputValues, "*" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:monthOfYear.everyMonth.label" ) );

		outputValues = listAppend( outputValues, "*/2" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:monthOfYear.everyOtherMonth.label" ) );

		outputValues = listAppend( outputValues, "*/3" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:monthOfYear.everyThirdMonth.label" ) );

		outputValues = listAppend( outputValues, "*/6" );
		outputLabels = listAppend( outputLabels, translateResource( uri="formcontrols.cronPickerItem:monthOfYear.everySixMonth.label" ) );

		return { values=outputValues, labels=outputLabels };
	}
}