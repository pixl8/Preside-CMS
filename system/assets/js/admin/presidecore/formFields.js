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

	$('.datetimepicker').datetimepicker({
		icons: {
            time: 'fa fa-clock-o',
            date: 'fa fa-calendar',
            up: 'fa fa-chevron-up',
            down: 'fa fa-chevron-down',
            previous: 'fa fa-chevron-left',
            next: 'fa fa-chevron-right',
            today: 'fa fa-screenshot',
            clear: 'fa fa-trash'
        },

        format: 'YYYY-MM-DD HH:mm',

        sideBySide:true
	});

	$('#derivative').change(function(){
		var width       = $('.image-dimensions-picker-width');
		var height      = $('.image-dimensions-picker-height');
		var derivative  = $('#derivative_chosen .chosen-hidden-field').val();
		var dimension   = $('#dimensions');
		var quality     = $('#quality');

		if( derivative === "none" ){
			width.prop('disabled', false);
			height.prop('disabled', false);

		}else{
			width.prop('disabled', 'disabled');
			height.prop('disabled', 'disabled');
		}
	});

} )( presideJQuery );