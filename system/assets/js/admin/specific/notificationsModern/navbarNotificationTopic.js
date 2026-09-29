( function( $ ){
	$('a#notificationBar').on('click',function(){
		var $link = $( this );
		
		if( !$link.parent().hasClass('open') ){
			var remoteUrl       = $link.data( 'href' );
			var targetContainer = $link.data( 'container' );
		
			$.ajax({
				  url  : remoteUrl
				, success : function( saveSuccess ) {
					$(targetContainer).find('li:not(:first-child):not(:last-child)').remove();
					$(targetContainer).find('li:nth-last-child(1)').before(saveSuccess);
				}
				, error : function( error ) {
				}
			});
		}
	});

} )( presideJQuery );