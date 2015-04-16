( function( $ ){

	var $uploadButton = $( "#upload-button" )
	  , $uploadForm   = $( "#upload-version-form" )
	  , $fileInput    = $uploadForm.length && $uploadForm.find( 'input[name="file"]' )
	  , allPresent    = $uploadButton.length && $uploadForm.length && $fileInput.length;

	if ( allPresent ) {
		$uploadButton.click( function( e ){
			e.preventDefault();
			$fileInput.click();
		} );

		$fileInput.on( "change", function(){
			$('body').presideLoadingSheen( true );
			$uploadForm.submit();
		} );
	}

} )( presideJQuery );