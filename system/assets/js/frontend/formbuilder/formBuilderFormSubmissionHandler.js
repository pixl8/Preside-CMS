if ( typeof window.jQuery !== "undefined" ) {
	( function( $ ){
		$.fn.presideFormBuilderForm = function(){
			return this.each( function(){
				var $form              = $( this )
				  , useJqueryValidate  = typeof $form.data( "validator" ) !== "undefined"
				  , submissionEndpoint = $form.attr( "action" )
				  , submitHandler
				  , successHandler
				  , errorHandler;

				submitHandler = function( e ){
					e.preventDefault();
					if ( useJqueryValidate && !$form.valid() ) {
						return;
					}

					$.ajax( submissionEndpoint, {
						  method  : "POST"
						, cache   : false
						, data    : $form.serialize()
						, success : successHandler
						, error   : errorHandler
					} );
				};

				successHandler = function( data ) {
					if ( typeof data !== "object" || typeof data.success === "undefined" ) {
						errorHandler( data );
					}

					if ( data.success ) {
						$form.parent().fadeOut( 200, function(){
							$form.parent().html( data.response ).fadeIn( 200 );
						} );
					} else {
						$form.validate().showErrors( data.errors );
					}
				};

				errorHandler = function( data ) {
					console.log( arguments );
					alert( "TODO: handler errors..." );
				};

				$form.on( "submit", submitHandler );
			} );
		};

	} )( jQuery );
}