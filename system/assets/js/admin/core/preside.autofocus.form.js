( function( $ ){
	var $form = $( "form[data-auto-focus-form=true]" ).first();

	if ( $form.length ) {
		$form.find( "input,select,textarea" ).not( ":hidden" ).first().focus();
	}
} )( presideJQuery );