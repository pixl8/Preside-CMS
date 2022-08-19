( function( $ ){

	var $preventCropControl = $( "[name=resize_no_crop]" )
	  , $croppingFieldsets = $( "#fieldset-focal_point, #fieldset-crop_hint" );

	$preventCropControl.on( "change", function(){
		$croppingFieldsets.toggle( !$( this ).is( ":checked" ) );
	} ).trigger( "change" );

} )( presideJQuery );