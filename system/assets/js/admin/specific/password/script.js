( function( $ ){

	$("body").on('click','.toggle-password', function() {

		$(this).toggleClass("fa-eye fa-eye-slash");
		var input = $($(this).attr("toggleid"));

		if( input.attr("type") == "password" ) {
			input.attr("type", "text");
		} else {
			input.attr("type", "password");
		}
	});


} )( presideJQuery );