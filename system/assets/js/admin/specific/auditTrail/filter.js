( function( $ ){

	$( "body" ).on( "click", 'button[data-bb-handler="ok"]', function( e ){
		e.preventDefault();
		var $form = $("form");
		$('body').presideLoadingSheen( true );
		$form.submit();
	} );

} )( presideJQuery );