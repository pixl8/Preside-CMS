( function( $ ){
	window.assetUploader = {
		getUploaded : function(){
			if ( typeof cfrequest.uploadedAssets === "undefined" ) {
				return [];
			}

			return cfrequest.uploadedAssets;
		},

		isComplete : function(){
			return typeof cfrequest.uploadedAssets !== "undefined";
		},

		nextStep : function(){
			$( '.asset-picker-upload-form:first' ).submit();
		}
	};

} )( presideJQuery );