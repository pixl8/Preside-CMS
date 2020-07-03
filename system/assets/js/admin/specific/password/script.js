( function( $ ){

	$("body").on('click','.toggle-password', function(e) {
		e.preventDefault();
		$(this).toggleClass("fa-eye fa-eye-slash");
		var input = $($(this).attr("href"));

		if( input.attr("type") == "password" ) {
			input.attr("type", "text");
		} else {
			input.attr("type", "password");
		}
	});


} )( presideJQuery );