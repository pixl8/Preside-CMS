( function( $ ){
	$(window).load(function(){

		xOffset = 10;
		yOffset = 30;


	    var target = $(".page-title");

	    $.each( $(".page-title"), function( index, value ){

	    	$(target).hover(function(e){
	    		var attr = $(this).data('image');
    	        if (typeof attr !== typeof undefined && attr !== false) {
				    var thumbnailUrl = $(this).data('image');
				    $("body").append("<p id='page-thumbnail'><img src='"+ thumbnailUrl +"' alt='url preview' /></p>");
				    $("#page-thumbnail")
					   .css("top",(e.pageY - xOffset) + "px")
					   .css("left",(e.pageX + yOffset) + "px")
					   .fadeIn("fast");
				}
		    },

			function(){
				$("#page-thumbnail").remove();
		    });


			$(target).mousemove(function(e){
				$("#page-thumbnail")
					.css("top",(e.pageY - xOffset) + "px")
					.css("left",(e.pageX + yOffset) + "px");
			});

	    });

	});

})( presideJQuery );
