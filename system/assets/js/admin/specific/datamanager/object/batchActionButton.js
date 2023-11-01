( function( $ ){

	$( ".batch-action-menu" ).each( function(){
		$batchActionsMenu = $( this );

		var $form             = $batchActionsMenu.closest( "form" )
		  , $multiActionField = $form.find( "[name=multiAction]" );

		$batchActionsMenu.on( "click", ".action", function(event){
			var action = $( this ).attr( "name" );

			event.preventDefault();

			$multiActionField.val( action );
			$form.submit();
		} );
	} );

} )( presideJQuery );