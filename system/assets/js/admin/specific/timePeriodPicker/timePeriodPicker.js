( function( $ ){
	$.fn.timePeriodPicker = function(){
		return this.each( function(){
			var $formControl             = $( this )
			  , $form                    = $formControl.closest( "form" )
			  , $builderContainer        = $formControl.next( "div.time-period-picker-wrapper" )
			  , $typeControl             = $builderContainer.find( ".time-period-type"    )
			  , $measureControl          = $builderContainer.find( ".time-period-measure" )
			  , $measure2Control         = $builderContainer.find( ".time-period-measure2" )
			  , $unitControl             = $builderContainer.find( "select.time-period-unit" )
			  , $unit2Control            = $builderContainer.find( "select.time-period-unit2" )
			  , $date1Control            = $builderContainer.find( ".time-period-date1" )
			  , $date2Control            = $builderContainer.find( ".time-period-date2" )
			  , $unitControlContainer    = $builderContainer.find( ".chosen-container.time-period-unit" )
			  , $date1ControlContainer   = $builderContainer.find( ".time-period-date1" ).parent()
			  , $date2ControlContainer   = $builderContainer.find( ".time-period-date2" ).parent()
			  , $secondaryMeasureGroup   = $builderContainer.find( ".time-period-measure-secondary" )
			  , $relativeEndpointLabels  = $builderContainer.find( ".time-period-relative-endpoint-label" )
			  , $relativeSuffixPast      = $builderContainer.find( ".time-period-relative-suffix-past" )
			  , $relativeSuffixFuture    = $builderContainer.find( ".time-period-relative-suffix-future" )
			  , $hiddenControl, initializePicker, showAndHideFieldsBasedOnPeriodType, getSelectedType, saveToHiddenField, hideRelativeBetweenFields;

			initializePicker = function() {
				var id       = $formControl.attr( "id" )
				  , name     = $formControl.attr( "name" )
				  , tabIndex = $formControl.attr( "tabindex" )
				  , val      = $formControl.val();

				$builderContainer.removeClass( "hide" );
				$hiddenControl = $( '<input type="hidden">' );
				$hiddenControl.val( val );
				$hiddenControl.attr( "name", name );
				$formControl.after( $hiddenControl );
				$formControl.remove();
				$hiddenControl.attr( "id", id );
				showAndHideFieldsBasedOnPeriodType();

				function updateTimePeriodValue() {
					showAndHideFieldsBasedOnPeriodType();
					saveToHiddenField();
				}

				$form.on( "click", updateTimePeriodValue );
				$typeControl.on( "change", updateTimePeriodValue );
				$measureControl.on( "change", updateTimePeriodValue );
				$measure2Control.on( "change", updateTimePeriodValue );
				$unitControl.on( "change", updateTimePeriodValue );
				$unit2Control.on( "change", updateTimePeriodValue );
				$date1Control.on( "change dp.change", updateTimePeriodValue );
				$date2Control.on( "change dp.change", updateTimePeriodValue );
			};

			hideRelativeBetweenFields = function(){
				$relativeEndpointLabels.addClass( "hide" );
				$relativeSuffixPast.addClass( "hide" );
				$relativeSuffixFuture.addClass( "hide" );
				$secondaryMeasureGroup.addClass( "hide" );
			};

			showAndHideFieldsBasedOnPeriodType = function(){
				var type = getSelectedType();

				hideRelativeBetweenFields();

				switch( type ) {
					case "between":
						$measureControl.addClass( "hide" );
						$unitControlContainer.addClass( "hide" );
						$date1ControlContainer.removeClass( "hide" ).addClass( "block" );
						$date2ControlContainer.removeClass( "hide" ).addClass( "block" );
					break;
					case "since":
					case "before":
					case "until":
					case "after":
					case "equal":
						$measureControl.addClass( "hide" );
						$unitControlContainer.addClass( "hide" );
						$date1ControlContainer.removeClass( "hide" ).addClass( "block" );
						$date2ControlContainer.addClass( "hide" ).removeClass( "block" );
					break;
					case "recent":
					case "upcoming":
					case "futureplus":
					case "pastminus":
						$measureControl.removeClass( "hide" );
						$unitControlContainer.removeClass( "hide" );
						$date1ControlContainer.addClass( "hide" ).removeClass( "block" );
						$date2ControlContainer.addClass( "hide" ).removeClass( "block" );
					break;
					case "betweenago":
					case "betweenupcoming":
						$measureControl.removeClass( "hide" );
						$unitControlContainer.removeClass( "hide" );
						$date1ControlContainer.addClass( "hide" ).removeClass( "block" );
						$date2ControlContainer.addClass( "hide" ).removeClass( "block" );
						$relativeEndpointLabels.removeClass( "hide" );
						$secondaryMeasureGroup.removeClass( "hide" );
						if ( type == "betweenago" ) {
							$relativeSuffixPast.removeClass( "hide" );
						} else {
							$relativeSuffixFuture.removeClass( "hide" );
						}
					break;
					case "futureequal":
					case "pastequal":
						$measureControl.removeClass( "hide" );
						$unitControlContainer.addClass( "hide" ).removeClass( "block" );
						$date1ControlContainer.addClass( "hide" ).removeClass( "block" );
						$date2ControlContainer.addClass( "hide" ).removeClass( "block" );
					break;

					default:
						$measureControl.addClass( "hide" );
						$unitControlContainer.addClass( "hide" );
						$date1ControlContainer.addClass( "hide" ).removeClass( "block" );
						$date2ControlContainer.addClass( "hide" ).removeClass( "block" );
				}

				var $date1 = $builderContainer.find( ".time-period-date1" );
				if ( $date1.length ) {
					var dtPicker = $date1.data( "DateTimePicker" );
					if ( dtPicker ) {
						if ( type == "equal" ) {
							$date1.data( "DateTimePicker" ).format( "YYYY-MM-DD" );
						} else {
							$date1.data( "DateTimePicker" ).format( "YYYY-MM-DD HH:mm" );
						}
					}
				}
			};

			saveToHiddenField = function(){
				var val = { type : getSelectedType() };

				switch( val.type ) {
					case "between":
 						val.date1 = $date1Control.val();
						val.date2 = $date2Control.val();
					break;
					case "since":
					case "before":
					case "until":
					case "after":
					case "equal":
 						val.date1 = $date1Control.val();
					break;
					case "recent":
					case "upcoming":
					case "futureplus":
					case "pastminus":
						val.measure = $measureControl.val();
						val.unit    = getSelectedUnit( $unitControl );
					break;
					case "betweenago":
					case "betweenupcoming":
						val.measure  = $measureControl.val();
						val.unit     = getSelectedUnit( $unitControl );
						val.measure2 = $measure2Control.val();
						val.unit2    = getSelectedUnit( $unit2Control );
					break;
					case "futureequal":
					case "pastequal":
						val.measure = $measureControl.val();
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
					case "lastyear":
					case "thisyear":
					case "nextyear":
						val.type = val.type;
					break;

					default:
						val.type = "alltime";
				}

				$hiddenControl.val( JSON.stringify( val ) );
			};

			getSelectedType = function(){
				var selected = $typeControl.data( "uberSelect" ).getSelected();
				return selected.length ? selected[0].value : $typeControl.val();
			};

			getSelectedUnit = function( $control ){
				var selected = $control.data( "uberSelect" ).getSelected();
				return selected.length ? selected[0].value : $control.val();
			};

			initializePicker();
		} );
	};

	$( ".time-period-picker-input" ).timePeriodPicker();
} )( presideJQuery );
