( function( $ ){

	var t = function( uri, fallback, data ) {
		return i18n.translateResource( uri, { data : data || [], defaultValue : fallback } );
	};

	window.PresideEverythingBar = function( options ) {
		this.options            = options || {};
		this.$toolbar           = options.$toolbar;
		this.$input             = this.$toolbar.find( ".everything-bar-input" );
		this.$dropdown          = this.$toolbar.find( ".everything-bar-dropdown" );
		this.$chips             = this.$toolbar.find( ".everything-bar-chips" );
		this.config             = options.config || {};
		this.activeSaved        = [];
		this.searchQuery        = "";
		this.highlightedIndex   = -1;
		this.itemData           = [];
		this.defaultPlaceholder = this.$input.attr( "placeholder" ) || "";
		this.onChange           = options.onChange || function(){};

		this._bind();
		this.renderChips();
	};

	PresideEverythingBar.prototype._bind = function() {
		var self = this;

		this.$input.on( "click input", function(){
			self.open();
		} );

		this.$input.on( "keydown", function( e ){
			self._onKey( e );
		} );

		this.$dropdown.on( "click", "[data-bar-action]", function( e ){
			e.preventDefault();
			e.stopPropagation();
			self._runAction( $( this ).data( "barAction" ), $( this ) );
		} );

		this.$chips.on( "click", ".everything-chip-remove", function( e ){
			e.preventDefault();
			self.removeChip( $( this ).closest( ".everything-chip" ) );
		} );

		$( document ).on( "click.everythingBar", function( e ){
			if ( !$( e.target ).closest( self.$input.add( self.$dropdown ).add( self.$chips ) ).length ) {
				self.close();
			}
		} );
	};

	PresideEverythingBar.prototype.isOpen = function() {
		return !this.$dropdown.hasClass( "hide" );
	};

	PresideEverythingBar.prototype.open = function() {
		this.renderDropdown();
		this.$dropdown.removeClass( "hide" );
		this.$toolbar.addClass( "is-open" );
	};

	PresideEverythingBar.prototype.close = function() {
		this.$dropdown.addClass( "hide" );
		this.$toolbar.removeClass( "is-open" );
		this.highlightedIndex = -1;
		this.$input.attr( "placeholder", this.defaultPlaceholder );
	};

	PresideEverythingBar.prototype.getQuery = function() {
		return $.trim( this.$input.val() );
	};

	PresideEverythingBar.prototype.setSearchQuery = function( query ) {
		this.searchQuery = query || "";
		this.renderChips();
	};

	PresideEverythingBar.prototype.getFavourites = function() {
		return this.activeSaved.join( "," );
	};

	PresideEverythingBar.prototype.setFavourites = function( ids ) {
		this.activeSaved = ids ? ( $.isArray( ids ) ? ids : String( ids ).split( "," ) ).filter( Boolean ) : [];
		this.renderChips();
	};

	PresideEverythingBar.prototype.renderChips = function() {
		var html = []
		  , i, saved;

		if ( this.searchQuery ) {
			html.push( this._chipHtml( "search", this.searchQuery, t( "cms:datatables.chip.search", "Search: {1}", [ this.searchQuery ] ) ) );
		}

		for( i=0; i<this.activeSaved.length; i++ ) {
			saved = this._savedById( this.activeSaved[ i ] );
			if ( saved ) {
				html.push( this._chipHtml(
					  saved.type === "segmentation" ? "segmentation" : "saved"
					, saved.id
					, saved.name
					, saved.type === "segmentation" ? "sitemap" : ( saved.favourite ? "heart" : "filter" )
				) );
			}
		}

		this.$chips.html( html.join( "" ) );
		this.$chips.toggleClass( "has-chips", html.length > 0 );
	};

	PresideEverythingBar.prototype._chipHtml = function( kind, id, label, icon ) {
		icon = icon || "filter";
		return '<span class="everything-chip everything-chip-' + kind + '" data-chip-kind="' + kind + '" data-chip-id="' + $("<div>").text( id ).html() + '">' +
			'<i class="fa fa-fw fa-' + icon + '"></i> ' +
			$("<div>").text( label ).html() +
			' <a href="#" class="everything-chip-remove" aria-label="Remove">&times;</a></span>';
	};

	PresideEverythingBar.prototype.removeChip = function( $chip ) {
		var kind = $chip.data( "chipKind" )
		  , id   = String( $chip.data( "chipId" ) );

		if ( kind === "search" ) {
			this.searchQuery = "";
			this.$input.val( "" );
		} else if ( kind === "saved" || kind === "segmentation" ) {
			this.activeSaved = this.activeSaved.filter( function( item ){ return String( item ) !== id; } );
		}

		this.renderChips();
		this.onChange();
	};

	PresideEverythingBar.prototype.renderDropdown = function() {
		var q            = this.getQuery().toLowerCase()
		  , items        = []
		  , html         = []
		  , saved        = this.config.savedFilters || []
		  , segmentation = this.config.segmentationFilters || []
		  , i, item;

		this.itemData = [];

		if ( this.config.allowSearch && q.length ) {
			items.push( { action : "search", label : t( "cms:datatables.everything.search.records", "Search records for “{1}”", [ this.getQuery() ] ), icon : "search", query : this.getQuery() } );
		}

		for( i=0; i<segmentation.length; i++ ) {
			item = segmentation[ i ];
			if ( this._matches( q, item.name ) ) {
				items.push( { action : "saved", id : item.id, label : item.name + " (" + ( item.count || 0 ) + ")", icon : "sitemap", group : t( "cms:datatables.everything.segmentation", "Segmentation" ) } );
			}
		}
		for( i=0; i<saved.length; i++ ) {
			item = saved[ i ];
			if ( this._matches( q, item.name ) || this._matches( q, item.folder ) ) {
				items.push( { action : "saved", id : item.id, label : item.name, icon : item.favourite ? "heart" : "filter", group : item.folder || t( "cms:datatables.everything.saved", "Saved filters" ) } );
			}
		}

		if ( !items.length ) {
			html.push( '<div class="everything-bar-empty">' + t( "cms:datatables.everything.empty", "No matching filters" ) + '</div>' );
		} else {
			html = this._groupedHtml( items );
		}

		this.$dropdown.html( html.join( "" ) );
		this._markHighlight();
	};

	PresideEverythingBar.prototype._groupedHtml = function( items ) {
		var html = []
		  , lastGroup = null
		  , i, item;

		for( i=0; i<items.length; i++ ) {
			item = items[ i ];
			if ( item.group && item.group !== lastGroup ) {
				html.push( '<div class="everything-bar-group">' + $("<div>").text( item.group ).html() + '</div>' );
				lastGroup = item.group;
			}
			html.push( this._itemHtml( item ) );
		}

		return html;
	};

	PresideEverythingBar.prototype._itemHtml = function( item ) {
		var index = this.itemData.length
		  , attrs = ' data-bar-action="' + item.action + '" data-index="' + index + '"';

		this.itemData.push( item );

		if ( item.id ) { attrs += ' data-id="' + item.id + '"'; }
		if ( item.href ) { attrs += ' data-href="' + item.href + '"'; }

		return '<a href="#" class="everything-bar-item" role="option"' + attrs + '>' +
			'<i class="fa fa-fw fa-' + ( item.icon || "filter" ) + '"></i> ' +
			$("<div>").text( item.label ).html() +
			'</a>';
	};

	PresideEverythingBar.prototype._key = function( e ) {
		return e.which || e.keyCode;
	};

	PresideEverythingBar.prototype._onKey = function( e ) {
		var key    = this._key( e )
		  , $items;

		if ( key === 27 ) {
			e.preventDefault();
			e.stopPropagation();
			this.close();
			this.$input.focus();
			return;
		}

		if ( key === 40 || key === 38 ) {
			e.preventDefault();
			e.stopPropagation();
			if ( !this.isOpen() ) {
				this.open();
				this.highlightedIndex = 0;
			} else {
				$items = this.$dropdown.find( ".everything-bar-item" );
				if ( key === 40 ) {
					this.highlightedIndex = Math.min( this.highlightedIndex + 1, Math.max( $items.length - 1, 0 ) );
				} else {
					this.highlightedIndex = Math.max( this.highlightedIndex - 1, 0 );
				}
			}
			this._markHighlight();
			return;
		}

		if ( key === 13 ) {
			e.preventDefault();
			e.stopPropagation();
			$items = this.$dropdown.find( ".everything-bar-item" );
			if ( this.highlightedIndex >= 0 && $items.eq( this.highlightedIndex ).length ) {
				$items.eq( this.highlightedIndex ).trigger( "click" );
			} else if ( this.config.allowSearch ) {
				this._runAction( "search" );
			}
		}
	};

	PresideEverythingBar.prototype._markHighlight = function() {
		var $items = this.$dropdown.find( ".everything-bar-item" );
		$items.removeClass( "is-highlighted" );
		if ( this.highlightedIndex >= 0 ) {
			$items.eq( this.highlightedIndex ).addClass( "is-highlighted" );
		}
	};

	PresideEverythingBar.prototype._itemAt = function( $el ) {
		var index = parseInt( $el.data( "index" ), 10 );
		if ( !isNaN( index ) && this.itemData[ index ] ) {
			return this.itemData[ index ];
		}
		return {};
	};

	PresideEverythingBar.prototype._runAction = function( action, $el ) {
		var item, id;

		$el   = $el || $();
		item  = this._itemAt( $el );
		id    = item.id || $el.data( "id" );

		switch( action ) {
			case "search":
				this.searchQuery = this.getQuery();
				this.$input.val( "" );
				this.close();
				this.renderChips();
				this.onChange();
			break;
			case "saved":
				id = String( id );
				if ( this.activeSaved.indexOf( id ) === -1 ) {
					this.activeSaved.push( id );
				} else {
					this.activeSaved = this.activeSaved.filter( function( savedId ){ return savedId !== id; } );
				}
				this.$input.val( "" );
				this.close();
				this.renderChips();
				this.onChange();
			break;
		}
	};

	PresideEverythingBar.prototype._savedById = function( id ) {
		var all = ( this.config.savedFilters || [] ).concat( this.config.segmentationFilters || [] )
		  , i;

		for( i=0; i<all.length; i++ ) {
			if ( String( all[ i ].id ) === String( id ) ) {
				return all[ i ];
			}
		}
		return null;
	};

	PresideEverythingBar.prototype._matches = function( query, value ) {
		if ( !query ) {
			return true;
		}
		return String( value || "" ).toLowerCase().indexOf( query ) !== -1;
	};

	PresideEverythingBar.prototype.refreshConfig = function( config ) {
		this.config = config || this.config;
		this.renderChips();
	};

} )( presideJQuery );
