( function( $ ){
	var $testButton = $( '#testConnection' );
	if( $testButton.length ){
		$( "button[type='submit']" ).addClass( 'disabled' );
		$testButton.on( "click", function( e ){
			e.preventDefault();
			var params = $( "form" ).serialize();
			$('body').presideLoadingSheen( true );
			$.ajax({
				  method  : "GET"
				, url     : buildAjaxLink( "sysconfig.testEmailConnection" )
				, data    : params
				, success : function(data){
					if( data.connection ){
						$( "button[type='submit']" ).removeClass( 'disabled' );
					}else{
						$( "button[type='submit']" ).addClass( 'disabled' );
					}
					$('body').presideLoadingSheen( false );
					presideBootbox.alert( data.msg );
				}
			});
		});
	}
} )( presideJQuery );