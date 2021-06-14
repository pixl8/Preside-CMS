( function( $ ){

	$( ".formbuilder-time-picker" ).each( function() {
		var $thisPicker      = $( this )
		  , pickerConfig     = $thisPicker.data()
		  , relativeToField  = pickerConfig.relativeToField  || ""
		  , relativeOperator = pickerConfig.relativeOperator || ""
		  , conf, $form, relativeField, timePicker;
		
		conf = {
			 startTime : pickerConfig.startTime || null
			, endTime   : pickerConfig.endTime   || null
			, language  : $thisPicker.data( "language" ) || "en"
			, onRender : function( time ){
				var timeValue  = time.valueOf()
				  , startTime  = this.startTime
				  , endTime    = this.endTime

				if ( typeof startTime != 'undefined' && startTime > timeValue ) {
					return 'disabled';
				}

				if ( typeof endTime != 'undefined' && endTime < timeValue ) {
					return 'disabled';
				}

				return '';
			}
		};

		$thisPicker.timepicker( conf ).next().on( "click", function(){
			$( this ).prev().focus();
		});

		$thisPicker.on("changeTime.timepicker", function(){
			if ( typeof $.validator !== 'undefined' ) {
				$thisPicker.valid();
			}
		});

		timePicker = $thisPicker.data( "timepicker" );

		if ( relativeToField.length || relativeOperator.length ) {
			$form          = $thisPicker.closest( "form" );
			$relativeField = $form.find( "[name=" + relativeToField + "]" );

			if ( $relativeField.length ) {
				var currentTime = $relativeField.val();

				if ( currentTime.length ) {
					currentTime = new Date( currentTime );
					switch( relativeOperator ) {
						case "lt":
							currentTime.setDate( currentTime.getDate() - 1 );
						case "lte":
							timePicker.setEndDate( currentTime );
						break;

						case "gt":
							currentTime.setDate( currentTime.getDate() + 1 );
						case "gte":
							timePicker.setStartDate( currentTime );
						break;
					}
				}

				$relativeField.on( "changeTime.timepicker", function( e ){
					var newTime   = new Date( e.time );
					    fieldTime = datetimePicker.date();

					switch( relativeOperator ) {
						case "lt":
							newTime.setDate( newTime.getDate() - 1 );
						case "lte":
							timePicker.setEndDate( newTime );
						break;

						case "gt":
							newTime.setDate( newTime.getDate() + 1 );
						case "gte":
							timePicker.setStartDate( newTime );
						break;
					}
				} );

			}
		}
	});
} )( jQuery );