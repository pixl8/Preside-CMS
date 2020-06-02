/**
 * Sets up the core keyboard navigation system for Preside
 */

( function( $ ){

	var $searchBox          = $( '#nav-search-input' )
	  , $sidebar            = $( '#sidebar' )
	  , $mainContainer      = $( '#main-container' )
	  , gotoMode            = false
	  , devConsoleToggleKey = parseInt( typeof cfrequest.devConsoleToggleKeyCode === "undefined" ? 96 : cfrequest.devConsoleToggleKeyCode )
	  , processArrows
	  , toggleGotoMode
	  , gotoAccessKeyLink
	  , genericKeyHandler
	  , escapeFeatures
	  , focusInSearchBox
	  , toggleSideBar
	  , toggleFixedWidth
	  , navigateWithinList
	  , traverseLists
	  , focusOnListItem
	  , blurCurrentFocus
	  , getFocusedList
	  , getNextAvailableTabIndex
	  , setupNavLists
	  , registerHotkeys
	  , switchUiTabs
	  , addHotKeyHints
	  , userIsTyping
	  , terminalIsPresent
	  , getTerminal
	  , terminalIsActive
	  , disableTerminal
	  , toggleTerminal
	  , isModifierPressed;

	registerHotkeys = function(){
		$('body').keydown( 'g'      , function( e ){ if( !userIsTyping() && !isModifierPressed( e ) ) { toggleGotoMode( e );   } } )
		         .keyup  ( '/'      , function( e ){ if( !userIsTyping() && !isModifierPressed( e ) ) { focusInSearchBox( e ); } } )
		         .keydown( 'esc'    , escapeFeatures )
		         .keydown( 'comma'  , function( e ){ if( !userIsTyping() && !isModifierPressed( e ) ) { toggleSidebar( e );    } } )
		         .keydown( 'period' , function( e ){ if( !userIsTyping() && !isModifierPressed( e ) ) { toggleFixedWidth( e ); } } )
		         .keydown( 't'      , function( e ){ if( !userIsTyping() && !isModifierPressed( e ) ) { switchUiTabs( e );     } } )
		         .keydown( 'up'     , function( e ){ if( !userIsTyping() && !isModifierPressed( e ) ) { processArrows( e, 'up'    ) } } )
		         .keydown( 'down'   , function( e ){ if( !userIsTyping() && !isModifierPressed( e ) ) { processArrows( e, 'down'  ) } } )
		         .keydown( 'left'   , function( e ){ if( !userIsTyping() && !isModifierPressed( e ) ) { processArrows( e, 'left'  ) } } )
		         .keydown( 'right'  , function( e ){ if( !userIsTyping() && !isModifierPressed( e ) ) { processArrows( e, 'right' ) } } )
		         .keypress( function( e ){ if ( e.which === devConsoleToggleKey ){ toggleTerminal(e) } } ) // cannot use jquery hotkeys for ` key mapping due to browser / keyboard inconsistencies
		         .keydown( genericKeyHandler );
	};

	isModifierPressed = function( e ) {
		return e.altKey || e.ctrlKey || e.metaKey || e.shiftKey;
	};

	setupNavLists = function(){
		var tabIx = getNextAvailableTabIndex();

		$( "[data-nav-list]" ).each( function(){
			var $navList = $( this );

			$navList.find( $navList.data( 'navListChildSelector' ) ).each( function(){
				var $child = $( this );
				if ( !$child.attr( 'tabindex' ) ) {
					$child.attr( 'tabindex', tabIx++ );
				}
			} );
		} );
	};

	addHotKeyHints = function(){
		var addHint = function( $el, keycombo ){
			var existingTitle = $el.attr( "title" )
			  , hotKeyText    = i18n.translateResource( "cms:hotkey.hint", { data : [ keycombo ] } )
			  , newTitle      = existingTitle && existingTitle.length ? ( existingTitle + " " + hotKeyText ) : hotKeyText;

			$el.data( "title", existingTitle );
			$el.attr( "title", newTitle );
		};

		$( "[data-global-key]" ).each( function(){
			var $this = $(this);
			addHint( $this, $this.data( "globalKey" ) );
		} );

		$( "[data-context-key]" ).each( function(){
			var $this = $(this);
			addHint( $this, $this.data( "contextKey" ) );
		} );

		$( "[data-goto-key]" ).each( function(){
			var $this = $(this);
			addHint( $this, "g + " + $this.data( "gotoKey" ) );
		} );


	};

	processArrows = function( e, direction ){
		var $focusedList = getFocusedList();

		if ( !$( ":focus" ).length || $focusedList !== null ) {
			if ( direction === "up" || direction === "down" ) {
				navigateWithinList( e, $focusedList, direction );
			} else {
				traverseLists( e, $focusedList, direction );
			}
			return;
		}

		// something focused that we don't manage - simulate tab / shift+tab
		if ( direction === "up" ) {
			$.tabPrev();
		} else if ( direction === "down" ) {
			$.tabNext();
		}
	};

	getFocusedList = function(){
		var $navLists = $( "[data-nav-list]" ).filter( ":visible" )
		  , $focused  = null;

		$navLists.each( function(){
			var $list     = $(this)
			  , $children = $list.find( $list.data( 'navListChildSelector' ) );

			$children.each( function(){
				$currentFocusedList = $list;
				if ( $(this).is(":focus") ) {
					$focused = $list;
					return false;
				}
			} );

			if ( $focused != null ) {
				return false;
			}
		} );

		return $focused;
	};

	navigateWithinList = function( e, $focusedList, direction ){
		var $currentList = $focusedList !== null ? $focusedList : $( "[data-nav-list]" ).filter( ":visible" ).first()
		  , $children
		  , currentFocus = -1, newFocus;

		e.preventDefault();

		if ( $currentList.length ) {
			$children = $currentList.find( $currentList.data( 'navListChildSelector' ) ).filter( ':visible' );

			$children.each( function( i ){
				var $child = $( this );
				if ( $child.is( ":focus" ) ) {
					currentFocus = i;
					return false;
				}
			} );

			switch( direction ){
				case "up":
					newFocus = currentFocus > 0 ? currentFocus-1 : 0;
				break;
				case "down":
					if ( currentFocus < 0 ) {
						newFocus = 0;
					} else {
						newFocus = currentFocus >= 0 && currentFocus < $children.length-1 ? currentFocus+1 : currentFocus;
					}
				break;
			}

			$( $children.get( newFocus ) ).focus();
		}
	};

	traverseLists = function( e, $focusedList, direction ){
		var $visibleLists = $( "[data-nav-list]" ).filter( ":visible" )
		  , currentIndex = -1
		  , newIndex;

		if ( $focusedList !== null && $focusedList.length ) {
			$visibleLists.each( function(i){
				if ( this === $focusedList.get(0) ) {
					currentIndex = i;
					return false;
				}
			} );
		}

		if ( direction === 'left' ) {
			if ( currentIndex <= 0 ) {
				newIndex = $visibleLists.length-1;
			} else {
				newIndex = currentIndex - 1;
			}
		} else {
			if ( currentIndex === -1 || currentIndex >= $visibleLists.length-1 ) {
				newIndex = 0;
			} else {
				newIndex = currentIndex + 1;
			}
		}

		if ( newIndex !== currentIndex ) {
			navigateWithinList( e, $( $visibleLists.get( newIndex ) ), "down" );
		}

	}

	blurCurrentFocus = function(){
		focusedList=null;
		$( ":focus" ).blur();
	};

	toggleGotoMode = function() {
		gotoMode = !gotoMode;

		if ( gotoMode ) {
			setTimeout( toggleGotoMode, 1000 );
		}
	};

	genericKeyHandler = function( e ){
		var chr      = String.fromCharCode( e.keyCode ).toLowerCase()
		  , $focused = $(':focus')
		  , $container
		  , $target;

		if ( userIsTyping() || isModifierPressed( e ) ) {
			if ( e.keyCode === 27 ) { // escape key
				if ( terminalIsActive() ) {
					disableTerminal();
				}
				$focused.blur();
			}
			return; // don't do any key handling when user is typing!
		}

		if ( chr.match( /^[a-z]$/ ) !== null ) {
			if ( gotoMode ) {
				gotoAccessKeyLink( chr );
				return;
			}

			if ( $focused.length ) {
				$container = $focused.closest( "[data-context-container]" );
				if ( $container.length )  {
					$target = $container.find( "[data-context-key=" + chr + "]" );
					if ( $target.length ) {
						$target.get(0).click();
						return;
					}
				}
			}

			$target = $( "[data-global-key=" + chr + "]" );
			if ( $target.length ) {
				if ( $target.attr( 'href' ) || $target.is( ":submit" ) || $target.is( ":button" ) ) {
					$target.get(0).click();
				} else {
					$target.focus();
					e.preventDefault();
				}
				return;
			}
		}
	};

	gotoAccessKeyLink = function( key ){
		var $gotoLink = $( '[data-goto-key=' + key + ']' );

		if ( $gotoLink.length ) {
			$gotoLink.get(0).click();
		}
	};

	focusInSearchBox = function(){
		$searchBox.focus();
	};

	escapeFeatures = function(){
		blurCurrentFocus();
	};

	toggleSidebar = function(){
		ace.settings.sidebar_collapsed( !$sidebar.hasClass('menu-min') );//@ ace-extra.js
	};

	toggleFixedWidth = function(){
		ace.settings.main_container_fixed( !$mainContainer.hasClass('container') );//@ ace-extra.js
	};

	getNextAvailableTabIndex = function(){
		var max = 0;
		$( "[tabindex]" ).each( function(){
			var ix = parseInt( $(this).attr( 'tabindex' ) );
			if ( !isNaN( ix ) && ix > max ) {
				max = ix;
			}
		} );

		return max+1;
	};

	switchUiTabs = function( e ){
		var $tabs     = $( ".nav-tabs > li" )
		  , tabCount  = $tabs.length
		  , nextFocus = 0;

		if ( tabCount ) {
			$tabs.each( function( i ){
				if ( $( this ).hasClass( "active" ) ) {
					nextFocus = i+1;
					return false;
				}
			} );

			if ( nextFocus >= tabCount ) {
				nextFocus = 0;
			}

			$( $tabs.get( nextFocus ) ).find( "a" ).first().click();
			escapeFeatures();
		}
	};

	userIsTyping = function(){
		var $focused = $(':focus')

		if ( terminalIsActive() ) {
			return true;
		}

		if ( !$focused.length ) {
			return false;
		}

		isInFormField = $.inArray( $focused.prop('nodeName'), [ 'INPUT','TEXTAREA' ] ) >= 0 && $.inArray( $focused.prop('type').toLowerCase(), [ 'checkbox','radio','submit','button' ] ) === -1;
		if ( isInFormField ) {
			return true;
		}
	};

	terminalIsPresent = function(){
		return typeof presideTerminal !== "undefined";
	};

	getTerminal = function(){
		return presideTerminal;
	};

	terminalIsActive = function(){
		return terminalIsPresent() && getTerminal().enabled();
	};

	disableTerminal = function(){
		terminalIsPresent() && getTerminal().disable();
	};

	toggleTerminal = function(){
		terminalIsPresent() && getTerminal().toggle();
	}

	setupNavLists();
	registerHotkeys();
	addHotKeyHints();

	window.userIsTyping = userIsTyping;

} )( presideJQuery );