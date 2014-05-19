PresideRichEditor = ( function( $ ){

	function PresideRichEditor( elementToReplace ) {
		this.init( elementToReplace );
	}

	PresideRichEditor.prototype.init = function( elementToReplace ){
		var $elementToReplace = $( elementToReplace )
		  , config       = {}
		  , toolbar      = $elementToReplace.data( "toolbar" )
		  , width        = $elementToReplace.data( "width" )
		  , height       = $elementToReplace.data( "height" )
		  , stylesheets  = $elementToReplace.data( "stylesheets" )
		  , customConfig = $elementToReplace.data( "customConfig" ) || cfrequest.ckeditorConfig
		  , editor;

		if ( toolbar && toolbar.length ) {
			config.toolbar = this.parseToolbarConfig( toolbar );
		}
		if ( stylesheets && stylesheets.length ) {
			config.contentsCss = stylesheets.split( "," );
		}
		if ( customConfig ) {
			config.customConfig = customConfig;
		}
		if ( width ) {
			config.width = width;
		}
		if ( height ) {
			config.height = height;
		}

		this.editor = CKEDITOR.replace( elementToReplace, config );

		$elementToReplace.data( 'ckeditorinstance', this.editor );
	};

	PresideRichEditor.prototype.parseToolbarConfig = function( rawToolbarText ){
		var bars = rawToolbarText.split( '|' )
		  , barCount = bars.length
		  , toolbar = []
		  , buttons
		  , bar, i, n;

		if ( rawToolbarText.match( /[\,\|]/g ) === null ) {
			return rawToolbarText;
		}

		for( i=0; i<barCount; i++ ){
			if ( !$.trim( bars[i] ).length || bars[i] === '/' ) {
				toolbar.push( "/" );
				continue;
			}

			buttons = bars[i].split(',');

			bar = { name:i, items:[] };
			for( n=0; n<buttons.length; n++ ){
				bar.items.push( buttons[n] );
			}
			toolbar.push( bar );
		}

		return toolbar;
	};


	return PresideRichEditor;

} )( presideJQuery );