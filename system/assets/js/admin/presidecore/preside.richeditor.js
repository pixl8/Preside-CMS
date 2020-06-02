PresideRichEditor = ( function( $ ){

	function PresideRichEditor( elementToReplace ) {
		this.init( elementToReplace );
	}

	PresideRichEditor.prototype.init = function( elementToReplace ){
		var $elementToReplace     = $( elementToReplace )
		  , config                = {}
		  , toolbar               = $elementToReplace.data( "toolbar" )            || cfrequest.ckeditorDefaultToolbar
		  , width                 = $elementToReplace.data( "width" )              || cfrequest.ckeditorDefaultWidth
		  , minHeight             = $elementToReplace.data( "minHeight" )          || cfrequest.ckeditorDefaultMinHeight
		  , maxHeight             = $elementToReplace.data( "maxHeight" )          || cfrequest.ckeditorDefaultMaxHeight
		  , customConfig          = $elementToReplace.data( "customConfig" )       || cfrequest.ckeditorConfig
		  , widgetCategories      = $elementToReplace.data( "widgetCategories" )   || cfrequest.widgetCategories   || ""
		  , linkPickerCategory    = $elementToReplace.data( "linkPickerCategory" ) || cfrequest.linkPickerCategory || ""
		  , stylesheets           = $elementToReplace.data( "stylesheets" )
		  , enterMode             = $elementToReplace.data( "enterMode" )
		  , autoParagraph         = $elementToReplace.data( "autoParagraph" ) !== undefined ? $elementToReplace.data( "autoParagraph" ) : cfrequest.ckeditorAutoParagraph
		  , defaultConfigs        = cfrequest.ckeditorDefaultConfigs || {}
		  , pasteFromWordDisallow = []
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
		if ( minHeight ) {
			config.autoGrow_minHeight = isNaN( parseInt( minHeight ) ) ? 0 : parseInt( minHeight );
		}
		if ( maxHeight ) {
			config.autoGrow_maxHeight = isNaN( parseInt( maxHeight ) ) ? 0 : parseInt( maxHeight );
		}
		if ( enterMode && enterMode.length ) {
			switch( enterMode.toLowerCase() ){
				case "br":
					config.enterMode = CKEDITOR.ENTER_BR;
					break;
				case "div":
					config.enterMode = CKEDITOR.ENTER_DIV;
					break;
				default:
					config.enterMode = CKEDITOR.ENTER_P;
			}
		}

		config.autoParagraph       = autoParagraph;
		config.widgetCategories    = widgetCategories;
		config.linkPickerCategory  = linkPickerCategory;

		for( var defaultConfig in defaultConfigs ) {
			if ( defaultConfig === "stylesheetParser_validSelectors" ) {
				config.stylesheetParser_validSelectors = new RegExp( defaultConfigs.stylesheetParser_validSelectors );
			} else {
				config[defaultConfig] = defaultConfigs[defaultConfig];
			}
		}

		pasteFromWordDisallow = config.pasteFromWordDisallow;

		CKEDITOR.on( "instanceReady", function( event ) {
			event.editor.initialdata = event.editor.getData();

			if ( pasteFromWordDisallow.length ) {
				event.editor.on( "afterPasteFromWord", function( event ) {
					var filter   = event.editor.filter.clone()
					  , fragment = CKEDITOR.htmlParser.fragment.fromHtml( event.data.dataValue )
					  , writer   = new CKEDITOR.htmlParser.basicWriter();

					pasteFromWordDisallow.forEach( function( item ){
						filter.disallow( item );
					} );

					filter.applyTo( fragment );
					fragment.writeHtml( writer );
					event.data.dataValue = writer.getHtml();
				} );
			}
		} );

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