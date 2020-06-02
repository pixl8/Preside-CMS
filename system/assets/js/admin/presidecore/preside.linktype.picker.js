( function( $ ){

	$( ".link-type-selector" ).on( "change", function(){
		var $linkType    = $( this )
		  , selectedType = $linkType.parent().find( ".chosen-hidden-field" ).val()
		  , $form        = $linkType.closest( "form" );

		$form.find( "fieldset.link-type-group" ).hide().filter( "#fieldset-" + selectedType ).show();
	} ).trigger( "change" );

} )( presideJQuery );