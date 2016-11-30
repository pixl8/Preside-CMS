( function( $ ){

	var $form = $( "#email-send-options" )

	if ( $form.length ) {
		var $scheduleFieldset       = $form.find( "#fieldset-schedule" )
		  , $scheduleFixedFieldset  = $form.find( "#fieldset-schedule_fixed" )
		  , $scheduleRepeatFieldset = $form.find( "#fieldset-schedule_repeat" )
		  , $limitDeetsFieldset     = $form.find( "#fieldset-limit_details" )
		  , $filterFieldset         = $form.find( "#fieldset-filter" )
		  , getRadioValue
		  , getSendMethod
		  , getScheduleType
		  , getLimitType
		  , enableFieldsetsBasedOnSendType
		  , enableFieldsetsBasedOnLimitType
		  , enableFieldsetsBasedOnScheduleType;

		getRadioValue = function( name ) {
			var $selectedRadio = $form.find( "[name=" + name + "]:checked" );

			if ( $selectedRadio.length ) {
				return $selectedRadio.val();
			}

			return "";
		}
		getSendMethod = function(){ return getRadioValue( "sending_method" ) };
		getScheduleType = function(){ return getRadioValue( "schedule_type" ) };
		getLimitType = function(){ return getRadioValue( "sending_limit" ) };

		enableFieldsetsBasedOnSendType = function(){
			var sendingMethod = getSendMethod();

			switch( sendingMethod ) {
				case "manual":
					$filterFieldset.show();
					$scheduleFieldset.hide();
					$scheduleFixedFieldset.hide();
					$scheduleRepeatFieldset.hide();
					enableFieldsetsBasedOnLimitType();
				break;
				case "auto":
					$filterFieldset.hide();
					$scheduleFieldset.hide();
					$scheduleFixedFieldset.hide();
					$scheduleRepeatFieldset.hide();
					enableFieldsetsBasedOnLimitType();

				break;
				case "scheduled":
					$filterFieldset.show();
					$scheduleFieldset.show();
					enableFieldsetsBasedOnScheduleType();
					enableFieldsetsBasedOnLimitType();
				break;
				default:
					$filterFieldset.hide();
					$scheduleFieldset.hide();
					$scheduleFixedFieldset.hide();
					$scheduleRepeatFieldset.hide();
					$limitDeetsFieldset.hide();
			}
		};
		enableFieldsetsBasedOnLimitType = function(){
			switch( getLimitType() ) {
				case "limited":
					$limitDeetsFieldset.show();
				break;
				case "none":
				case "once":
				default:
					$limitDeetsFieldset.hide();
			}
		};
		enableFieldsetsBasedOnScheduleType = function(){
			switch( getScheduleType() ) {
				case "repeat":
					$scheduleFixedFieldset.hide();
					$scheduleRepeatFieldset.show();
				break;
				case "fixeddate":
					$scheduleFixedFieldset.show();
					$scheduleRepeatFieldset.hide();
				break;
				default:
					$scheduleFixedFieldset.hide();
					$scheduleRepeatFieldset.hide();
			}
		};

		$form.on( "click", "[name=sending_method]", enableFieldsetsBasedOnSendType     );
		$form.on( "click", "[name=schedule_type]" , enableFieldsetsBasedOnScheduleType );
		$form.on( "click", "[name=sending_limit]" , enableFieldsetsBasedOnLimitType    );

		enableFieldsetsBasedOnSendType();
		enableFieldsetsBasedOnLimitType();
	}

} )( presideJQuery );