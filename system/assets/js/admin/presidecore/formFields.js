( function( $ ){

	$(".object-picker").presideObjectPicker();
	$(".asset-picker").uberAssetSelect();
	$(".image-dimension-picker").imageDimensionPicker();

	$(".auto-slug").each( function(){
		var $this = $(this)
		  , $basedOn = $this.parents("form:first").find("[name='" + $this.data( 'basedOn' ) + "']");

		$basedOn.keyup( function(e){
			var slug = $basedOn.val().replace( /\W/g, "-" ).replace( /-+/g, "-" ).toLowerCase();

			$this.val( slug );
		} );
	});

	$( 'textarea[class*=autosize]' ).autosize( {append: "\n"} );
	$( 'textarea[class*=limited]' ).each(function() {
		var limit = parseInt($(this).attr('data-maxlength')) || 100;
		$(this).inputlimiter({
			"limit": limit,
			remText: '%n character%s remaining...',
			limitText: 'max allowed : %n.'
		});
	});
	$( 'textarea.richeditor' ).not( '.frontend-container' ).each( function(){
		new PresideRichEditor( this );
	} );

	$('.date-picker')
		.datepicker( { autoclose:true } )
		.next().on( "click", function(){
			$(this).prev().focus();
		});

	$('[data-rel=popover]').popover({container:'body'});


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