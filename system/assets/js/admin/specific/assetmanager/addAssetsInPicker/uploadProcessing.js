( function( $ ){

	var $forms          = $( 'form.add-asset-form' )
	  , savedAssets     = []
	  , activeFormIndex = 0
	  , getActiveForm, setActiveForm, processActiveForm, isComplete, getUploaded, nextStep;

	getActiveForm = function(){
		return $forms.filter( ".active" ).first();
	};

	setActiveForm = function( ix ){
		$forms.removeClass( "active" );
		$( $forms.get( ix ) ).addClass( "active" );
	};

	processActiveForm = function( callback ){
		var $form = getActiveForm();

		if ( $form.valid() ) {
			$.ajax({
				  type    : "POST"
				, url     : $form.attr( 'action' )
				, data    : $form.serialize()
				, success : function( data ) { callback( true, data ); }
				, error   : function() { callback( false ); }
			});
		}
	};

	isComplete = function(){
		return savedAssets.length === $forms.length;
	};

	getUploaded = function(){
		return savedAssets;
	};

	nextStep = function(){
		if ( !isComplete() ) {
			processActiveForm( function( success, data ){
				if ( success && data.success ) {
					savedAssets.push( data.id );
					setActiveForm( ++activeFormIndex );
				}
			} );
		}
	};

	setActiveForm( activeFormIndex );


	window.assetUploader = {
		getUploaded : getUploaded,
		isComplete  : isComplete,
		nextStep    : nextStep
	};

} )( presideJQuery );