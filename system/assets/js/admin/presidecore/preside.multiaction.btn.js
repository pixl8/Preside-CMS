( function( $ ){

	$( "[data-multi-submit-field]" ).each( function(){
		var $btn         = $( this )
		  , $form        = $btn.closest( "form" )
		  , $actionField = $form.find( "[name=" + $btn.data( "multiSubmitField" ) + "]" );

		$btn.on( "click", "[data-action-key]", function( e ){
			e.preventDefault();

			var $actionLink = $( this )
			  , key         = $actionLink.data( "actionKey" );

			$actionField.val( key );
			$form.submit();
		} );

	} );



} )( presideJQuery );