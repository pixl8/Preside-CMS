( function( $ ){

	var $carouselContainer = $("#version-carousel")
	  , carousel, activeIndex;

	if ( $carouselContainer.length ) {
		activeIndex = $carouselContainer.find( '.current-version' ).index();

		$carouselContainer.owlCarousel({
			  navigation      : false
			, slideSpeed      : 300
			, paginationSpeed : 400
			, singleItem      : true
		});

		carousel = $carouselContainer.data( 'owlCarousel' );

		carousel.jumpTo( activeIndex );
	}
} )( presideJQuery );