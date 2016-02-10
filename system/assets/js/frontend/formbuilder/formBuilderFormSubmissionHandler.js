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
				var fileFields='';
				$.each($form.find('input[type=file]'),function(key,value){
					if(fileFields.length){
						fileFields=fileFields+',';
					}
					fileFields=fileFields+value.name;
				});
				if(fileFields.length){
					$form.append("<input type='hidden' name='fileFields' value='"+fileFields+"' >");
				}
				submitHandler = function( e ){
					e.preventDefault();
					if ( useJqueryValidate && !$form.valid() ) {
						return;
					}
					var formData = new FormData($(this)[0]);
					$.ajax( submissionEndpoint, {
						  method  : "POST"
						, cache   : false
						, data    : formData
						, success : successHandler
						, error   : errorHandler
						, async	  : false
						, contentType: false
						, processData: false
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