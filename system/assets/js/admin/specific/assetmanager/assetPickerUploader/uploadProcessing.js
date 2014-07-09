( function( $ ){
	window.assetUploader = {
		nextStep : function(){
			$( '.asset-picker-upload-form:first' ).submit();
		}
	};

} )( presideJQuery );