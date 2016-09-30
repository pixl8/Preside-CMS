( function( $ ){
	var showActiveUsers = $( '#showActiveUsers' );
	var allUsers        = $( '#allUsers_wrapper' );
	var activeUsers     = $( '#activeUsers_wrapper' );
	var userData = function(element){
		if( !element.prop( "checked" ) ){
			allUsers.show();
			activeUsers.hide();
		} else{
			allUsers.hide();
			activeUsers.show();
		}
	}
	showActiveUsers.on( "click",function(){
		userData($(this));
	} );

	userData(showActiveUsers);
} )( presideJQuery );