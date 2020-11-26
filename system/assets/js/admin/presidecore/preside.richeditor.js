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
		  , customDefaultConfigs  = $elementToReplace.data( "customDefaultConfigs" ) || {}
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
		for( var customDefaultConfig in customDefaultConfigs ) {
			if ( customDefaultConfig === "stylesheetParser_validSelectors" ) {
				config.stylesheetParser_validSelectors = new RegExp( customDefaultConfigs.stylesheetParser_validSelectors );
			} else {
				config[customDefaultConfig] = customDefaultConfigs[customDefaultConfig];
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

		CKEDITOR.on( "dialogDefinition", function( event ) {
			var dialogDefinition = event.data.definition
			  , $parent          = $( parent.CKEDITOR.document.$ )
			  , $dialogIframe    = $parent.find( ".cke_dialog_ui_iframe:visible, .bootbox-body > iframe:visible" )
			  , $parentModal     = $parent.find( ".bootbox.modal:visible" )
			  , $parentEditor    = $parent.find( ".cke_dialog:visible" )
			  , nestedInModal    = $parentModal.length
			  , nestedInEditor   = $parentEditor.length
			  , originalOnShow   = dialogDefinition.onShow || function(){}
			  , originalOnHide   = dialogDefinition.onHide || function(){}
			  , dialogWidth      = $dialogIframe.width()
			  , dialogHeight     = $dialogIframe.height();

			if ( nestedInEditor ) {
				dialogDefinition.onShow = function() {
					originalOnShow.call( this );

					var iframeId  = this._.contents.iframe && this._.contents.iframe.undefined.domId;
					if ( !iframeId ) return;

					$parentEditor.addClass( "is-parent-dialog" );
					$dialogIframe.width( dialogWidth+20 ).height( dialogHeight+106 );

					this.move( 0, 0 );
					this.resize( dialogWidth, dialogHeight-3 );

					setTimeout( function(){
						$( "#"+iframeId ).width( dialogWidth-2 ).height( dialogHeight-22 );
					}, 100 );
				}

				dialogDefinition.onHide = function() {
					originalOnHide.call( this );

					var iframeId  = this._.contents.iframe && this._.contents.iframe.undefined.domId;
					if ( !iframeId ) return;

					$parentEditor.removeClass( "is-parent-dialog" );
					$dialogIframe.width( dialogWidth-20 ).height( dialogHeight-106 );
				}
			} else if ( nestedInModal ) {
				dialogDefinition.onShow = function() {
					originalOnShow.call( this );

					$parentModal.addClass( "is-parent-dialog" );

					var iframeId  = this._.contents.iframe.undefined.domId;

					this.move( 0, 0 );
					this.resize( dialogWidth, dialogHeight-17 );

					setTimeout( function(){
						$( "#"+iframeId ).width( dialogWidth-22 ).height( dialogHeight-36 );
					}, 100 );
				}

				dialogDefinition.onHide = function() {
					$parentModal.removeClass( "is-parent-dialog" );
				}
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