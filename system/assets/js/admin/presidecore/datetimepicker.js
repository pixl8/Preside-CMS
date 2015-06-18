( function( $ ){

	$('.date-picker').change(function() {
		var getDate 	= $(this).val();
		var attrId 		= $(this).attr('id');
		var InputId		= attrId.replace("_date","");
		var getHour		= $('#'+InputId+'_hour').val();
		var getMin		= $('#'+InputId+'_min').val();
		var datTime		= getDate+" "+getHour+":"+getMin;
		$('.'+InputId).val(datTime);
	});

	$('.time-picker-hour').change(function() {
		var getHour 	= $(this).val();
		var attrId 		= $(this).attr('id');
		var InputId		= attrId.replace("_hour","");
		var getDate 	= $('#'+InputId+'_date').val();
		var getMin		= $('#'+InputId+'_min').val();
		var datTime		= getDate+" "+getHour+":"+getMin;
		$('.'+InputId).val(datTime);
	});

	$('.time-picker-min').change(function() {
		var getMin	 	= $(this).val();
		var attrId 		= $(this).attr('id');
		var InputId		= attrId.replace("_min","");
		var getDate 	= $('#'+InputId+'_date').val();
		var getHour		= $('#'+InputId+'_hour').val();
		var datTime		= getDate+" "+getHour+":"+getMin;
		$('.'+InputId).val(datTime);
	});
} )( presideJQuery );