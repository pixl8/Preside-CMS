( function( $ ){

	$('.datetimepicker').each( function() {
		var $thisPicker      = $( this )
		  , pickerConfig     = $thisPicker.data()
		  , relativeToField  = pickerConfig.relativeToField
		  , relativeOperator = pickerConfig.relativeOperator
		  , defaultDate      = pickerConfig.defaultDate
		  , conf, $form, relativeField, datetimePicker;

		conf = {
			  icons          : {
				  time:     'fa fa-clock-o'
				, date:     'fa fa-calendar'
				, up:       'fa fa-chevron-up'
				, down:     'fa fa-chevron-down'
				, previous: 'fa fa-chevron-left'
				, next:     'fa fa-chevron-right'
				, today:    'fa fa-screenshot'
				, clear:    'fa fa-trash'
			}
			, format         : 'YYYY-MM-DD HH:mm'
            , useCurrent     : false
            , defaultHour    : pickerConfig.defaultHour    || 0
            , defaultMinutes : pickerConfig.defaultMinutes || 0
			, minDate        : pickerConfig.startDate      || false
			, maxDate        : pickerConfig.endDate        || false
			, sideBySide     : true
			, locale         : pickerConfig.language       || "en"
		};

		$thisPicker.datetimepicker( conf ).next().on( "click", function(){
			$( this ).prev().focus();
		});

		$thisPicker.on( "dp.change", function(){
			if ( typeof $.validator !== 'undefined' ) {
				$thisPicker.valid();
			}
		});

		$thisPicker.on( "dp.show", function(){
			var dp = $thisPicker.data( "DateTimePicker" )
			  , currentDate = $.trim( $thisPicker.val() );

			if ( currentDate === "" ) {
				dp.date( moment( defaultDate ).hours( pickerConfig.defaultHour || 0 ).minutes( pickerConfig.defaultMinutes || 0 ).seconds(0).milliseconds(0) );
			}
		} );

		datetimePicker = $thisPicker.data( "DateTimePicker" );

		if ( relativeToField.length && relativeOperator.length ) {
			$form          = $thisPicker.closest( "form" );
			$relativeField = $form.find( "[name=" + relativeToField + "]" );

			if ( $relativeField.length ) {
				var currentDate = $relativeField.val();
				var fieldDate   = datetimePicker.date();

				if ( currentDate.length ) {
					currentDate = new Date( currentDate );

					switch( relativeOperator ) {
						case "lt":
							currentDate.setDate( currentDate.getDate() - 1 );
						case "lte":
							datetimePicker.maxDate( currentDate );
							if( fieldDate == null ){
								datetimePicker.clear();
							}
						break;

						case "gt":
							currentDate.setDate( currentDate.getDate() + 1 );
						case "gte":
							datetimePicker.minDate( currentDate );
							if( fieldDate == null ){
								datetimePicker.clear();
							}
						break;
					}
				}

				$relativeField.on( "dp.change", function( e ){
					var newDate   = new Date( e.date );
					    fieldDate = datetimePicker.date();

					switch( relativeOperator ) {
						case "lt":
							newDate.setDate( newDate.getDate() - 1 );
						case "lte":
							datetimePicker.maxDate( newDate );
							if( fieldDate == null ){
								datetimePicker.clear();
							}
						break;

						case "gt":
							newDate.setDate( newDate.getDate() + 1 );
						case "gte":
							datetimePicker.minDate( newDate );
							if( fieldDate == null ){
								datetimePicker.clear();
							}
						break;
					}
				} );

			}
		}
	});

} )( presideJQuery );