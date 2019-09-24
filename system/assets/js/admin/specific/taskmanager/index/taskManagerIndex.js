( function( $ ){

	$( ".task-manager-tab" ).on( "click", function(){
		var tabId = $( this ).data( "tabId" );
		$.cookie( "_presideTaskManagerTab", tabId );
	} );

} )( presideJQuery );