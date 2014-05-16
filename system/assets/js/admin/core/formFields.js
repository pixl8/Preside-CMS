( function( $ ){

	$(".uber-select").uberSelect( { allow_single_deselect : true, inherit_select_classes : true } );
	$(".asset-picker").assetPicker();
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
} )( presideJQuery );