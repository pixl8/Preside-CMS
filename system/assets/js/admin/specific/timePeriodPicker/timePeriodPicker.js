( function( $ ){
	$.fn.timePeriodPicker = function(){
		return this.each( function(){
			var $formControl           = $( this )
			  , $form                  = $formControl.closest( "form" )
			  , $builderContainer      = $formControl.next( "div.time-period-picker-wrapper" )
			  , $typeControl           = $builderContainer.find( ".time-period-type"    )
			  , $measureControl        = $builderContainer.find( ".time-period-measure" )
			  , $unitControl           = $builderContainer.find( "select.time-period-unit" )
			  , $date1Control          = $builderContainer.find( ".time-period-date1" )
			  , $date2Control          = $builderContainer.find( ".time-period-date2" )
			  , $unitControlContainer  = $builderContainer.find( ".chosen-container.time-period-unit" )
			  , $date1ControlContainer = $builderContainer.find( ".time-period-date1" ).parent()
			  , $date2ControlContainer = $builderContainer.find( ".time-period-date2" ).parent()
			  , $hiddenControl, initializePicker, showAndHideFieldsBasedOnPeriodType, getSelectedType, saveToHiddenField;

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
				$form.on( "click change dp.change", function(){
					showAndHideFieldsBasedOnPeriodType();
					saveToHiddenField();
				} );
			};

			showAndHideFieldsBasedOnPeriodType = function(){
				switch( getSelectedType() ) {
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

					default:
						$measureControl.addClass( "hide" );
						$unitControlContainer.addClass( "hide" );
						$date1ControlContainer.addClass( "hide" ).removeClass( "block" );
						$date2ControlContainer.addClass( "hide" ).removeClass( "block" );
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
 						val.date1 = $date1Control.val();
					break;
					case "recent":
					case "upcoming":
					case "futureplus":
					case "pastminus":
						val.measure = $measureControl.val();
						val.unit    = getSelectedUnit();
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

			getSelectedUnit = function(){
				var selected = $unitControl.data( "uberSelect" ).getSelected();
				return selected.length ? selected[0].value : $unitControl.val();
			};



			initializePicker();
		} );
	};

	$( ".time-period-picker-input" ).timePeriodPicker();
} )( presideJQuery );