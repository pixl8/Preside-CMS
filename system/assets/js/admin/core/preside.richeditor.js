PresideRichEditor = ( function( $ ){

	function PresideRichEditor( elementToReplace ) {
		this.init( elementToReplace );
	}

	PresideRichEditor.prototype.init = function( elementToReplace ){
		var $elementToReplace = $( elementToReplace )
		  , config       = {}
		  , toolbar      = $elementToReplace.data( "toolbar" )
		  , customConfig = $elementToReplace.data( "customConfig" ) || cfrequest.ckeditorConfig
		  , editor;

		if ( toolbar && toolbar.length ) {
			config.toolbar = toolbar;
		}

		if ( customConfig ) {
			config.customConfig = customConfig;
		}

		this.editor = CKEDITOR.replace( elementToReplace, config );

		$elementToReplace.data( 'ckeditorinstance', this.editor );
	};


	return PresideRichEditor;

} )( presideJQuery );