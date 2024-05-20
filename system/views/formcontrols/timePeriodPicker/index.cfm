<!---@feature presideForms--->
<cfscript>
	inputName      = args.name         ?: "";
	inputId        = args.id           ?: "";
	inputClass     = args.class        ?: "";
	defaultValue   = args.defaultValue ?: "";
	pastOnly       = IsTrue( args.pastOnly   ?: "" );
	futureOnly     = IsTrue( args.futureOnly ?: "" );
	isDate         = IsTrue( args.isDate     ?: "" );
	datePickerType = isDate ? "datePicker" : "dateTimePicker";

	minDate = futureOnly ? now() : "";
	maxDate = pastOnly   ? now() : "";

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	timePeriod = args.timePeriod ?: {};
</cfscript>

<cfoutput>
	<textarea id="#inputId#" name="#inputName#" class="form-control time-period-picker-input" tabindex="#getNextTabIndex()#">#value#</textarea>
	<div class="time-period-picker-wrapper hide">
		#renderFormControl(
			  name         = ( inputName & "_period_type" )
			, type         = "timePeriodTypePicker"
			, savedValue   = timePeriod.type ?: "alltime"
			, defaultValue = timePeriod.type ?: "alltime"
			, class        = "time-period-type"
			, pastOnly     = pastOnly
			, futureOnly   = futureOnly
			, layout       = ""
		)#

		<div class="time-period-measure-unit-group">
			#renderFormControl(
				  name         = ( inputName & "_period_measure" )
				, type         = "spinner"
				, class        = "time-period-measure-unit-input time-period-measure form-control"
				, savedValue   = timePeriod.measure ?: 1
				, defaultValue = timePeriod.measure ?: 1
				, layout       = ""
			)#

			#renderFormControl(
				  name         = ( inputName & "_period_unit" )
				, type         = "timePeriodUnitPicker"
				, class        = "time-period-measure-unit-input time-period-unit"
				, isDate       = isDate
				, savedValue   = timePeriod.unit ?: "d"
				, defaultValue = timePeriod.unit ?: "d"
				, layout       = ""
			)#
		</div>

		#renderFormControl(
			  name         = ( inputName & "_period_date1" )
			, type         = datePickerType
			, class        = "time-period-date1"
			, savedValue   = timePeriod.date1 ?: ""
			, defaultValue = timePeriod.date1 ?: ""
			, layout       = ""
			, minDate      = minDate
			, maxDate      = maxDate 
		)#

		#renderFormControl(
			  name         = ( inputName & "_period_date2" )
			, type         = datePickerType
			, class        = "time-period-date2"
			, savedValue   = timePeriod.date2 ?: ""
			, defaultValue = timePeriod.date2 ?: ""
			, layout       = ""
			, minDate      = minDate
			, maxDate      = maxDate 
		)#
	</div>
</cfoutput>
