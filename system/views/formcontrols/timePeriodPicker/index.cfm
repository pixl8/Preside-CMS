<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	pastOnly     = IsTrue( args.pastOnly   ?: "" );
	futureOnly   = IsTrue( args.futureOnly ?: "" );

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
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

		#renderFormControl(
			  name         = ( inputName & "_period_measure" )
			, type         = "spinner"
			, class        = "time-period-measure"
			, savedValue   = timePeriod.measure ?: 1
			, defaultValue = timePeriod.measure ?: 1
			, layout       = ""
		)#

		#renderFormControl(
			  name         = ( inputName & "_period_unit" )
			, type         = "timePeriodUnitPicker"
			, class        = "time-period-unit"
			, savedValue   = timePeriod.unit ?: "d"
			, defaultValue = timePeriod.unit ?: "d"
			, layout       = ""
		)#

		#renderFormControl(
			  name         = ( inputName & "_period_date1" )
			, type         = "dateTimePicker"
			, class        = "time-period-date1"
			, savedValue   = timePeriod.date1 ?: ""
			, defaultValue = timePeriod.date1 ?: ""
			, layout       = ""
		)#

		#renderFormControl(
			  name         = ( inputName & "_period_date2" )
			, type         = "dateTimePicker"
			, class        = "time-period-date2"
			, savedValue   = timePeriod.date2 ?: ""
			, defaultValue = timePeriod.date2 ?: ""
			, layout       = ""
		)#
	</div>
</cfoutput>