( function( $ ){

	$(".uber-select").uberSelect( { allow_single_deselect : true, inherit_select_classes : true } );
	$(".asset-picker").assetPicker();

	$(".spinner-input").each( function(){
		var $this = $(this);

		$this.ace_spinner( {
			  value          : $this.val()
			, min            : $this.data("min") || 0
			, max            : $this.data("max")
			, step           : $this.data("step")
			, btn_up_class   : 'btn-info'
			, btn_down_class : 'btn-info'
		} );
	} );

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

	$('.date-picker')
		.datepicker( { autoclose:true } )
		.next().on( "click", function(){
			$(this).prev().focus();
		});
} )( presideJQuery );