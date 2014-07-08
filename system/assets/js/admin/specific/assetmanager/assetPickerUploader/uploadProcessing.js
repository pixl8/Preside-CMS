( function( $ ){
	window.assetUploader = {
		isComplete : function(){
			return false;
		},

		nextStep : function(){
			$( '.asset-picker-upload-form:first' ).submit();
		}
	};

} )( presideJQuery );