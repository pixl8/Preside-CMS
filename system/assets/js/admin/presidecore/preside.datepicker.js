( function( $ ){


	$('.date-picker').each( function() {
		var $thisPicker      = $( this )
		  , pickerConfig     = $thisPicker.data()
		  , relativeToField  = pickerConfig.relativeToField
		  , relativeOperator = pickerConfig.relativeOperator
		  , conf, $form, relativeField, datePicker;

		conf = {
			  autoclose : true
			, startDate : pickerConfig.startDate || null
			, endDate   : pickerConfig.endDate   || null
			, language  : $thisPicker.data( "language" ) || "en"
			, onRender : function( date ){
				var dateValue  = date.valueOf()
				  , startDate  = this.startDate
				  , endDate    = this.endDate

				if ( typeof startDate != 'undefined' && startDate > dateValue ) {
					return 'disabled';
				}

				if ( typeof endDate != 'undefined' && endDate < dateValue ) {
					return 'disabled';
				}

				return '';
			}
		};

		$thisPicker.datepicker( conf ).next().on( "click", function(){
			$( this ).prev().focus();
		});

		$thisPicker.on("changeDate", function(){
			if ( typeof $.validator !== 'undefined' ) {
				$thisPicker.valid();
			}
		});

		datePicker = $thisPicker.data( "datepicker" );

		if ( relativeToField.length || relativeOperator.length ) {
			$form          = $thisPicker.closest( "form" );
			$relativeField = $form.find( "[name=" + relativeToField + "]" );

			if ( $relativeField.length ) {
				var currentDate = $relativeField.val();

				if ( currentDate.length ) {
					currentDate = new Date( currentDate );
					switch( relativeOperator ) {
						case "lt":
							currentDate.setDate( currentDate.getDate() - 1 );
						case "lte":
							datePicker.setEndDate( currentDate );
						break;

						case "gt":
							currentDate.setDate( currentDate.getDate() + 1 );
						case "gte":
							datePicker.setStartDate( currentDate );
						break;
					}
				}

				$relativeField.on( "changeDate", function( e ){
					var newDate   = new Date( e.date );
					    fieldDate = datetimePicker.date();

					switch( relativeOperator ) {
						case "lt":
							newDate.setDate( newDate.getDate() - 1 );
						case "lte":
							datePicker.setEndDate( newDate );
						break;

						case "gt":
							newDate.setDate( newDate.getDate() + 1 );
						case "gte":
							datePicker.setStartDate( newDate );
						break;
					}
				} );

			}
		}
	});

} )( presideJQuery );