( function( $ ){

    $(".object-picker").presideObjectPicker();
	$(".object-configurator").presideObjectConfigurator();
	$(".asset-picker").uberAssetSelect();
	$(".image-dimension-picker").imageDimensionPicker();

	$(".auto-slug").each( function(){
		var $this = $(this)
		  , $basedOn = $this.parents("form:first").find("[name='" + $this.data( 'basedOn' ) + "']");

		$basedOn.keyup( function(e){
			var slug = $basedOn.val().replace( /\W/g, "-" ).replace( /-+/g, "-" ).replace( /^-/, "" ).replace( /-$/, "" ).toLowerCase();

			$this.val( slug ).trigger( "keyup" );
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

	$('[data-rel=popover]').popover({container:'body'});

	$('.timepicker').each( function(){
        $( this ).datetimepicker({
    		icons: {
                time:     'fa fa-clock-o',
                date:     'fa fa-calendar',
                up:       'fa fa-chevron-up',
                down:     'fa fa-chevron-down',
                previous: 'fa fa-chevron-left',
                next:     'fa fa-chevron-right',
                today:    'fa fa-screenshot',
                clear:    'fa fa-trash'
            },
            format: 'HH:mm',
            sideBySide:true,
            locale: ( $(this).data( "language" ) || "en" )
        });
	});

    $(".derivative-select-option").each( function(){
    	var $derivativeField   = $( this )
    	  , $parentForm        = $derivativeField.closest( "form" )
    	  , $dimensionField    = $parentForm.find( "[name=dimension]" )
    	  , $widthField        = $parentForm.find( ".image-dimensions-picker-width" )
    	  , $heightField       = $parentForm.find( ".image-dimensions-picker-height" )
    	  , $qualityField      = $parentForm.find( "#quality" )
    	  , $choosenDerivative = $parentForm.find( "[name=derivative]" );

    	$derivativeField.change( function(){
            if( $choosenDerivative.val() === "none"){

            	$widthField.prop('disabled', false);
            	$heightField.prop('disabled', false);
            	$qualityField.prop( "disabled", false ).data("uberSelect").search_field_disabled();

            }else{

            	$widthField.prop('disabled', true);
            	$heightField.prop('disabled', true);
            	$qualityField.prop( "disabled", true );
            	$qualityField.data("uberSelect").search_field_disabled();
            }
    	});

    	if( $choosenDerivative.val() != "none" ){

    		$widthField.prop('disabled', true);
            $heightField.prop('disabled', true);
            $qualityField.prop( "disabled", true );
            $qualityField.data("uberSelect").search_field_disabled();

    	}
    });

} )( presideJQuery );
