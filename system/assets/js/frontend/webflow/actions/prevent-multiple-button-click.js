( function( $ ){

	$.fn.webflowPreventMultipleSubmit = function(){
		return this.each( function(){

			var $wfForm     = $( this )
			  , wfSubmitBtn = ".webflow-next-btn"
			  , wfBtnLinks  = "a.webflow-prev-btn, a.prevent-multiple-click";

			$wfForm.on( "disableSubmit", function() {
				$( wfSubmitBtn, $wfForm ).prop( "disabled", true );
				$( wfBtnLinks , $wfForm ).addClass( "disabled" );
			} ).on( "enableSubmit", function() {
				$( wfSubmitBtn, $wfForm ).prop( "disabled", false );
				$( wfBtnLinks , $wfForm ).removeClass( "disabled" );
			} );

			$wfForm.on( "submit", function( event ) {
				$wfForm.trigger( "disableSubmit" );

				if ( $(this).valid && !$(this).valid() ) {
					$wfForm.trigger( "enableSubmit" );
				}
			} );

			$( wfBtnLinks, $wfForm ).on( "click", function( event ) {
				if ( $( this ).hasClass( "disabled" ) ) {
					event.preventDefault();
				}
				$wfForm.trigger( "disableSubmit" );
			} );

		} );
	};

	$( "form.webflow-form" ).webflowPreventMultipleSubmit();

} )( jQuery || presideJQuery );
