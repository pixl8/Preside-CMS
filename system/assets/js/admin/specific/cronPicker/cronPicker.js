( function( $ ){
	var parseCronExpressionHelper = function() {
		var parseCronExpression = cfrequest.cronExpressionReadableEndpoint || "";
		if ( parseCronExpression !== "" ) {
			$.ajax({
				url: parseCronExpression,
				data: { expression: $(".cron-picker").val() }
			}).done(function( output ) {
				$(".cron-readable-config").html( output );
			});
		}
	};

	parseCronExpressionHelper();

	$( ".cron-picker-common-item .chosen-hidden-field" ).each( function(){
		$( this ).on( "change", function(e) {
			if ( $(this).val() !== undefined ) {
				$( ".cron-item-" + $(this).attr("name") ).val( $(this).val() );

				updateCronPickerValue();
			}
		});
	} );

	$( ".cron-picker-item" ).each( function(){
		$(this).on( "change", function(e) {
			updateCronPickerValue();
		});
	} );

	var updateCronPickerValue = function() {
		$(".cron-picker").val(
			$( ".cron-item-second"      ).val() + " " +
			$( ".cron-item-minute"      ).val() + " " +
			$( ".cron-item-hour"        ).val() + " " +
			$( ".cron-item-dayofmonth"  ).val() + " " +
			$( ".cron-item-monthofyear" ).val() + " " +
			$( ".cron-item-dayofweek"   ).val()
		);

		parseCronExpressionHelper();
	};

	var updateIndividualFieldWithCommonSetting = function() {
		var cronValue     = $(".cron-picker").val();
		var splitedValues = cronValue.split(' ');

		$( ".cron-item-second"      ).val( splitedValues[0] );
		$( ".cron-item-minute"      ).val( splitedValues[1] );
		$( ".cron-item-hour"        ).val( splitedValues[2] );
		$( ".cron-item-dayofmonth"  ).val( splitedValues[3] );
		$( ".cron-item-monthofyear" ).val( splitedValues[4] );
		$( ".cron-item-dayofweek"   ).val( splitedValues[5] );
	}

	$(".cron-picker-general-common .chosen-hidden-field").on( "change", function(e) {
		$(".cron-picker").val( $(this).val() );

		updateIndividualFieldWithCommonSetting();
		parseCronExpressionHelper();
	} );
} )( presideJQuery );