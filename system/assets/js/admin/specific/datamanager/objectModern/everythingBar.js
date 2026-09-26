( function( $ ){

	var t = function( uri, fallback, data ) {
		return i18n.translateResource( uri, { data : data || [], defaultValue : fallback } );
	};

	window.PresideEverythingBar = function( options ) {
		this.options               = options || {};
		this.$toolbar              = options.$toolbar;
		this.$input                = this.$toolbar.find( ".everything-bar-input" );
		this.$dropdown             = this.$toolbar.find( ".everything-bar-dropdown" );
		this.$chips                = this.$toolbar.find( ".everything-bar-chips" );
		this.config                = options.config || {};
		this.objectName            = options.objectName || this.config.objectName || "";
		this.listingKey            = options.listingKey || this.config.listingKey || this.objectName;
		this.activeSaved           = [];
		this.columnFilters         = [];
		this.extraFilters          = [];
		this.searchQuery           = "";
		this.viewFiltersLocked     = false;
		this.lockedSavedIds        = {};
		this.lockedColumnFields    = {};
		this.highlightedIndex      = -1;
		this.itemData              = [];
		this.navigationData        = [];
		this.expandedSections      = { favourites : true };
		this.ajaxBusy              = false;
		this.defaultPlaceholder    = this.$input.attr( "placeholder" ) || "";
		this.onChange              = options.onChange || function(){};
		this.onRemoveColumnFilter  = options.onRemoveColumnFilter || function(){};
		this.onApplyView           = options.onApplyView || function(){};
		this.onApplyAjaxResult     = options.onApplyAjaxResult || function(){ return false; };
		this.getListingFilterState = options.getListingFilterState || function(){ return {}; };

		this._bind();
		this.renderChips();
	};

	PresideEverythingBar.actions = PresideEverythingBar.actions || {};

	PresideEverythingBar.prototype._bind = function() {
		var self = this;

		this.$input.on( "click", function(){
			self.open();
		} );

		this.$input.on( "input", function(){
			self.highlightedIndex = -1;
			self.open();
		} );

		this.$input.on( "keydown keypress keyup", function( e ){
			e.stopPropagation();
		} );

		this.$input.on( "keydown", function( e ){
			self._onKey( e );
		} );

		this.$dropdown.on( "click", "[data-bar-action]", function( e ){
			e.preventDefault();
			e.stopPropagation();
			if ( $( this ).hasClass( "is-busy" ) ) {
				return;
			}
			self._runAction( $( this ).data( "barAction" ), $( this ) );
		} );

		this.$dropdown.on( "click", "[data-bar-section]", function( e ){
			e.preventDefault();
			e.stopPropagation();
			self._toggleSection( String( $( this ).data( "barSection" ) ) );
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
		if ( !this.ajaxBusy ) {
			this.renderDropdown();
		}
		this.$dropdown.removeClass( "hide" );
		this.$toolbar.addClass( "is-open" );
		this.$input.attr( "aria-expanded", "true" );
	};

	PresideEverythingBar.prototype.close = function() {
		this.$dropdown.addClass( "hide" );
		this.$toolbar.removeClass( "is-open" );
		this.highlightedIndex = -1;
		this.$input.attr( "placeholder", this.defaultPlaceholder );
		this.$input.attr( "aria-expanded", "false" );
		this.$input.removeAttr( "aria-activedescendant" );
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

	PresideEverythingBar.prototype.setColumnFilters = function( chips ) {
		this.columnFilters = chips || [];
		this.renderChips();
	};

	PresideEverythingBar.prototype.setFilterLock = function( spec ) {
		var self = this;

		spec = spec || {};
		this.viewFiltersLocked  = !!spec.locked;
		this.lockedSavedIds     = {};
		this.lockedColumnFields = {};

		$.each( spec.savedIds || [], function( i, id ) {
			self.lockedSavedIds[ String( id ) ] = true;
		} );
		$.each( spec.columnFields || [], function( i, field ) {
			self.lockedColumnFields[ String( field ) ] = true;
		} );

		this.renderChips();
		if ( this.isOpen() ) {
			this.renderDropdown();
		}
	};

	PresideEverythingBar.prototype.setFiltersLocked = function( locked ) {
		this.setFilterLock( { locked : locked } );
	};

	PresideEverythingBar.prototype._chipCanRemove = function( kind, id ) {
		if ( kind === "search" || kind === "extra" || !this.viewFiltersLocked ) {
			return true;
		}
		if ( kind === "saved" || kind === "segmentation" ) {
			return !this.lockedSavedIds[ String( id ) ];
		}
		if ( kind === "column" ) {
			return !this.lockedColumnFields[ String( id ) ];
		}
		return true;
	};

	PresideEverythingBar.prototype.renderChips = function() {
		var html = []
		  , i, saved, column, extra;

		if ( this.searchQuery ) {
			html.push( this._chipHtml( "search", this.searchQuery, t( "cms:datatables.chip.search", "Search: {1}", [ this.searchQuery ] ) ) );
		}

		for( i=0; i<this.extraFilters.length; i++ ) {
			extra = this.extraFilters[ i ];
			html.push( this._chipHtml( "extra", extra.id, extra.label, extra.icon || "magic" ) );
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

		for( i=0; i<this.columnFilters.length; i++ ) {
			column = this.columnFilters[ i ];
			html.push( this._chipHtml( "column", column.field, column.label, "filter" ) );
		}

		this.$chips.html( html.join( "" ) );
		this.$chips.toggleClass( "has-chips", html.length > 0 );
	};

	PresideEverythingBar.prototype._chipHtml = function( kind, id, label, icon ) {
		var canRemove = this._chipCanRemove( kind, id )
		  , lockLabel = $("<div>").text( t( "cms:datatables.chip.locked", "Locked" ) ).html();

		icon = icon || "filter";
		return '<span class="everything-chip everything-chip-' + kind + ( canRemove ? "" : " is-locked" ) + '" data-chip-kind="' + kind + '" data-chip-id="' + $("<div>").text( id ).html() + '">' +
			'<i class="fa fa-fw fa-' + icon + '"></i> ' +
			$("<div>").text( label ).html() +
			( canRemove
				? ' <a href="#" class="everything-chip-remove" aria-label="Remove">&times;</a>'
				: ' <i class="fa fa-fw fa-lock everything-chip-lock" title="' + lockLabel + '" aria-label="' + lockLabel + '"></i>'
			) +
			'</span>';
	};

	PresideEverythingBar.prototype.removeChip = function( $chip ) {
		var kind = $chip.data( "chipKind" )
		  , id   = String( $chip.data( "chipId" ) );

		if ( !this._chipCanRemove( kind, id ) ) {
			return;
		}

		if ( kind === "search" ) {
			this.searchQuery = "";
			this.$input.val( "" );
		} else if ( kind === "extra" ) {
			this.extraFilters = this.extraFilters.filter( function( item ){ return String( item.id ) !== id; } );
		} else if ( kind === "saved" || kind === "segmentation" ) {
			this.activeSaved = this.activeSaved.filter( function( item ){ return String( item ) !== id; } );
		} else if ( kind === "column" ) {
			this.columnFilters = this.columnFilters.filter( function( item ){ return String( item.field ) !== id; } );
			this.renderChips();
			this.onRemoveColumnFilter( id );
			return;
		}

		this.renderChips();
		this.onChange();
	};

	PresideEverythingBar.prototype.renderDropdown = function() {
		var query    = this.getQuery().toLowerCase()
		  , sections = this._buildSections( query )
		  , actions  = this._queryItems( query )
		  , html     = []
		  , i;

		this.itemData = [];
		this.navigationData = [];

		if ( this.viewFiltersLocked ) {
			html.push( '<div class="everything-bar-locked-note">' + t( "cms:datatables.views.filters.locked", "This view's filters stay applied. You can add more, or edit the view to change them." ) + '</div>' );
		}

		for( i=0; i<actions.length; i++ ) {
			html.push( this._itemHtml( actions[ i ] ) );
		}
		for( i=0; i<sections.length; i++ ) {
			html.push( this._sectionHtml( sections[ i ], !!query.length ) );
		}

		if ( !actions.length && !sections.length ) {
			html.push( '<div class="everything-bar-empty">' + t( "cms:datatables.everything.empty", "No matching filters" ) + '</div>' );
		}

		this.$dropdown.html( html.join( "" ) );
		if ( this.highlightedIndex >= this.navigationData.length ) {
			this.highlightedIndex = this.navigationData.length - 1;
		}
		this._markHighlight();
	};

	PresideEverythingBar.prototype._queryItems = function( q ) {
		var items = [];

		if ( this.config.allowSearch && q.length ) {
			items.push( {
				  action : "search"
				, label  : t( "cms:datatables.everything.search.records", "Search records for “{1}”", [ this.getQuery() ] )
				, icon   : "search"
			} );
		}

		this._appendItems( items, this._queryActionItems( q ) );

		return items;
	};

	PresideEverythingBar.prototype._buildSections = function( q ) {
		var sections           = []
		  , saved             = this.config.savedFilters || []
		  , segmentation      = this.config.segmentationFilters || []
		  , favourites        = []
		  , uncategorised     = []
		  , segmentationItems = []
		  , folders           = {}
		  , folderNames       = []
		  , labels         = {
			  favourites    : t( "cms:datatables.everything.favourites", "Favourites" )
			, segmentation  : t( "cms:datatables.everything.segmentation", "Segmentation filters" )
			, uncategorised : t( "cms:datatables.everything.uncategorised", "Uncategorised filters" )
			, views         : t( "cms:datatables.everything.views", "Views" )
		    }
		  , i, item, folder;

		for( i=0; i<saved.length; i++ ) {
			item   = saved[ i ];
			folder = String( item.folder || "" );

			if ( item.favourite ) {
				if ( this._matches( q, item.name ) || this._matches( q, labels.favourites ) ) {
					favourites.push( this._savedItem( item, labels.favourites, "heart" ) );
				}
			} else if ( folder.length ) {
				if ( this._matches( q, item.name ) || this._matches( q, folder ) ) {
					if ( !folders[ folder ] ) {
						folders[ folder ] = [];
						folderNames.push( folder );
					}
					folders[ folder ].push( this._savedItem( item, folder, "folder" ) );
				}
			} else if ( this._matches( q, item.name ) || this._matches( q, labels.uncategorised ) ) {
				uncategorised.push( this._savedItem( item, labels.uncategorised, "filter" ) );
			}
		}

		for( i=0; i<segmentation.length; i++ ) {
			item = segmentation[ i ];
			if ( this._matches( q, item.name ) || this._matches( q, labels.segmentation ) ) {
				segmentationItems.push( {
					  action    : "saved"
					, id        : item.id
					, label     : item.name + " (" + ( item.count || 0 ) + ")"
					, icon      : "sitemap"
					, group     : labels.segmentation
					, groupIcon : "sitemap"
				} );
			}
		}

		folderNames.sort( function( a, b ){
			return String( a ).toLowerCase().localeCompare( String( b ).toLowerCase() );
		} );

		this._appendSection( sections, "favourites", labels.favourites, "heart", favourites, true );
		this._appendSection( sections, "segmentation", labels.segmentation, "sitemap", segmentationItems );
		for( i=0; i<folderNames.length; i++ ) {
			this._appendSection(
				  sections
				, "folder-" + this._sectionKey( folderNames[ i ] )
				, folderNames[ i ]
				, "folder"
				, folders[ folderNames[ i ] ]
			);
		}
		this._appendSection( sections, "uncategorised", labels.uncategorised, "filter", uncategorised );
		this._appendSection( sections, "views", labels.views, "th-list", this._viewItems( q, labels.views ) );

		return sections;
	};

	PresideEverythingBar.prototype._appendSection = function( sections, key, label, icon, items, defaultExpanded ) {
		if ( items && items.length ) {
			sections.push( {
				  key             : key
				, label           : label
				, icon            : icon
				, items           : items
				, defaultExpanded : !!defaultExpanded
			} );
		}
	};

	PresideEverythingBar.prototype._sectionKey = function( value ) {
		var text = String( value || "" ).toLowerCase()
		  , slug = text.replace( /[^a-z0-9]+/g, "-" ).replace( /^-|-$/g, "" )
		  , hash = 0
		  , i;

		for( i=0; i<text.length; i++ ) {
			hash = ( ( hash << 5 ) - hash ) + text.charCodeAt( i );
			hash |= 0;
		}

		return ( slug || "folder" ) + "-" + Math.abs( hash );
	};

	PresideEverythingBar.prototype._queryActionItems = function( q ) {
		var items   = []
		  , actions = this.config.everythingBarActions || []
		  , i, action;

		for( i=0; i<actions.length; i++ ) {
			action = actions[ i ];
			if ( !action || !action.id ) {
				continue;
			}
			if ( action.requireQuery !== false && !q.length ) {
				continue;
			}
			items.push( {
				  action   : action.id
				, id       : action.id
				, label    : this._actionLabel( action )
				, icon     : action.icon || "magic"
				, endpoint : action.endpoint || ""
				, chipIcon : action.chipIcon || action.icon || "magic"
			} );
		}

		return items;
	};

	PresideEverythingBar.prototype._actionLabel = function( action ) {
		var query    = this.getQuery()
		  , fallback = String( action.label || action.id || "" ).split( "{1}" ).join( query );

		if ( action.labelUri ) {
			return t( action.labelUri, fallback, [ query ] );
		}

		return fallback;
	};

	PresideEverythingBar.prototype._viewItems = function( q, group ) {
		var items        = []
		  , views        = this.config.savedViews || []
		  , defaultLabel = t( "cms:datatables.views.default", "Default" )
		  , mine         = []
		  , shared       = []
		  , resolvedId   = this.config.resolvedDefaultViewId || ""
		  , i, view, hasNamedDefault;

		if ( !this.config.allowSavedViews ) {
			return items;
		}

		hasNamedDefault = false;
		if ( resolvedId && resolvedId !== "default" ) {
			for( i=0; i<views.length; i++ ) {
				if ( views[ i ].id === resolvedId ) {
					hasNamedDefault = true;
					break;
				}
			}
		}

		if ( !hasNamedDefault && ( this._matches( q, defaultLabel ) || this._matches( q, group ) ) ) {
			items.push( this._viewItem( "default", defaultLabel, group ) );
		}

		for( i=0; i<views.length; i++ ) {
			view = views[ i ];
			if ( this._matches( q, view.label ) || this._matches( q, view.description ) || this._matches( q, group ) ) {
				if ( view.owner ) {
					mine.push( this._viewItem( view.id, view.label, group ) );
				} else {
					shared.push( this._viewItem( view.id, view.label, group ) );
				}
			}
		}

		this._appendItems( items, mine );
		this._appendItems( items, shared );

		return items;
	};

	PresideEverythingBar.prototype._viewItem = function( id, label, group ) {
		return {
			  action    : "view"
			, id        : id
			, label     : label
			, icon      : "th-list"
			, group     : group
			, groupIcon : "th-list"
		};
	};

	PresideEverythingBar.prototype._savedItem = function( item, group, groupIcon ) {
		return {
			  action    : "saved"
			, id        : item.id
			, label     : item.name
			, icon      : item.favourite ? "heart" : "filter"
			, group     : group
			, groupIcon : groupIcon
		};
	};

	PresideEverythingBar.prototype._appendItems = function( items, extra ) {
		if ( extra && extra.length ) {
			Array.prototype.push.apply( items, extra );
		}
	};

	PresideEverythingBar.prototype._sectionHtml = function( section, searching ) {
		var expanded    = searching || this._sectionIsExpanded( section )
		  , sectionId   = this.$dropdown.attr( "id" ) + "-" + section.key
		  , navigation = this.navigationData.length
		  , html       = []
		  , i;

		this.navigationData.push( {
			  type       : "section"
			, sectionKey : section.key
		} );

		html.push(
			'<div class="everything-bar-group" role="treeitem" tabindex="-1" data-bar-section="' + this._html( section.key ) + '" data-nav-index="' + navigation + '"' +
				' id="' + sectionId + '-toggle" aria-expanded="' + ( expanded ? "true" : "false" ) + '" aria-controls="' + sectionId + '">' +
				'<i class="fa fa-fw fa-caret-' + ( expanded ? "down" : "right" ) + ' everything-bar-disclosure"></i>' +
				'<i class="fa fa-fw fa-' + section.icon + ' everything-bar-group-icon"></i>' +
				'<span class="everything-bar-group-label">' + this._html( section.label ) + '</span>' +
				'<span class="everything-bar-group-count">' + section.items.length + '</span>' +
			'</div>'
		);

		html.push( '<div class="everything-bar-section-items' + ( expanded ? "" : " hide" ) + '" id="' + sectionId + '" role="group" aria-labelledby="' + sectionId + '-toggle">' );
		if ( expanded ) {
			for( i=0; i<section.items.length; i++ ) {
				html.push( this._itemHtml( section.items[ i ], section.key ) );
			}
		}
		html.push( '</div>' );

		return html.join( "" );
	};

	PresideEverythingBar.prototype._sectionIsExpanded = function( section ) {
		if ( Object.prototype.hasOwnProperty.call( this.expandedSections, section.key ) ) {
			return this.expandedSections[ section.key ];
		}
		return section.defaultExpanded;
	};

	PresideEverythingBar.prototype._toggleSection = function( key, expanded ) {
		var current = this.expandedSections[ key ];

		if ( this.getQuery().length ) {
			this._highlightSection( key );
			return;
		}

		if ( typeof current === "undefined" ) {
			current = key === "favourites";
		}
		this.expandedSections[ key ] = typeof expanded === "boolean" ? expanded : !current;
		this.renderDropdown();
		this._highlightSection( key );
	};

	PresideEverythingBar.prototype._highlightSection = function( key ) {
		var i;

		for( i=0; i<this.navigationData.length; i++ ) {
			if ( this.navigationData[ i ].type === "section" && this.navigationData[ i ].sectionKey === key ) {
				this.highlightedIndex = i;
				this._markHighlight();
				return;
			}
		}
	};

	PresideEverythingBar.prototype._itemHtml = function( item, sectionKey ) {
		var index = this.itemData.length
		  , navigation = this.navigationData.length
		  , itemId = this.$dropdown.attr( "id" ) + "-item-" + navigation
		  , attrs = ' data-bar-action="' + item.action + '" data-index="' + index + '" data-nav-index="' + navigation + '" id="' + itemId + '"';

		this.itemData.push( item );
		this.navigationData.push( {
			  type       : "item"
			, sectionKey : sectionKey || ""
		} );

		if ( item.id ) { attrs += ' data-id="' + item.id + '"'; }
		if ( item.href ) { attrs += ' data-href="' + item.href + '"'; }

		return '<a href="#" class="everything-bar-item" role="treeitem" tabindex="-1"' + attrs + '>' +
			'<i class="fa fa-fw fa-' + ( item.icon || "filter" ) + '"></i> ' +
			$("<div>").text( item.label ).html() +
			'</a>';
	};

	PresideEverythingBar.prototype._html = function( value ) {
		return $( "<div>" ).text( value ).html();
	};

	PresideEverythingBar.prototype._key = function( e ) {
		return e.which || e.keyCode;
	};

	PresideEverythingBar.prototype._onKey = function( e ) {
		var key = this._key( e )
		  , navigation, $target;

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
				this.highlightedIndex = key === 40 ? 0 : Math.max( this.navigationData.length - 1, 0 );
			} else {
				if ( key === 40 ) {
					this.highlightedIndex = Math.min( this.highlightedIndex + 1, Math.max( this.navigationData.length - 1, 0 ) );
				} else {
					this.highlightedIndex = Math.max( this.highlightedIndex - 1, 0 );
				}
			}
			this._markHighlight();
			return;
		}

		navigation = this.navigationData[ this.highlightedIndex ];

		if ( ( key === 39 || key === 37 ) && navigation ) {
			e.preventDefault();
			e.stopPropagation();
			if ( navigation.type === "section" ) {
				this._toggleSection( navigation.sectionKey, key === 39 );
			} else if ( key === 37 && navigation.sectionKey ) {
				this._highlightSection( navigation.sectionKey );
			}
			return;
		}

		if ( key === 13 || ( key === 32 && navigation ) ) {
			e.preventDefault();
			e.stopPropagation();
			if ( navigation && navigation.type === "section" ) {
				this._toggleSection( navigation.sectionKey );
			} else if ( navigation ) {
				$target = this.$dropdown.find( '[data-nav-index="' + this.highlightedIndex + '"]' );
				$target.trigger( "click" );
			} else if ( this.config.allowSearch ) {
				this._runAction( "search" );
			}
		}
	};

	PresideEverythingBar.prototype._markHighlight = function() {
		var $items = this.$dropdown.find( "[data-nav-index]" )
		  , $highlighted;

		$items.removeClass( "is-highlighted" );
		$items.attr( "aria-selected", "false" );
		if ( this.highlightedIndex >= 0 ) {
			$highlighted = this.$dropdown.find( '[data-nav-index="' + this.highlightedIndex + '"]' );
			$highlighted.addClass( "is-highlighted" );
			$highlighted.attr( "aria-selected", "true" );
			this.$input.attr( "aria-activedescendant", $highlighted.attr( "id" ) );
		} else {
			this.$input.removeAttr( "aria-activedescendant" );
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
				if ( this.viewFiltersLocked && this.lockedSavedIds[ id ] && this.activeSaved.map( String ).indexOf( id ) !== -1 ) {
					this.close();
					return;
				}
				if ( this.activeSaved.map( String ).indexOf( id ) === -1 ) {
					this.activeSaved.push( id );
				} else {
					this.activeSaved = this.activeSaved.filter( function( savedId ){ return String( savedId ) !== id; } );
				}
				this.$input.val( "" );
				this.close();
				this.renderChips();
				this.onChange();
			break;
			case "view":
				this.$input.val( "" );
				this.close();
				this.onApplyView( String( id ) );
			break;
			default:
				this._runPluginAction( item, $el, action );
		}
	};

	PresideEverythingBar.prototype._runPluginAction = function( item, $el, action ) {
		var actionId = item.action || action;
		var runner   = PresideEverythingBar.actions[ actionId ];

		if ( typeof runner === "function" ) {
			runner.call( this, item, this );
			return;
		}

		if ( item.endpoint ) {
			this._runAjaxAction( item, $el );
		}
	};

	PresideEverythingBar.prototype._runAjaxAction = function( item, $el ) {
		var self = this;

		if ( this.ajaxBusy ) {
			return;
		}

		this.ajaxBusy = true;
		$el.addClass( "is-busy" );
		$el.find( "i.fa" ).attr( "class", "fa fa-fw fa-spinner fa-spin" );

		$.ajax( {
			  url      : item.endpoint
			, type     : "POST"
			, dataType : "json"
			, data     : {
				  object         : this.objectName
				, listingKey     : this.listingKey
				, query          : this.getQuery()
				, currentFilters : JSON.stringify( this.getCurrentFilters() )
			  }
			, success : function( result ) {
				self.ajaxBusy = false;
				if ( self._applyAjaxFilterResult( item, result ) ) {
					self.$input.val( "" );
					self.close();
					self.onChange();
					return;
				}
				self._pluginError( result && ( result.message || result.error ) );
				self.renderDropdown();
			  }
			, error : function() {
				self.ajaxBusy = false;
				self._pluginError();
				self.renderDropdown();
			  }
		} );
	};

	PresideEverythingBar.prototype.getCurrentFilters = function() {
		var extra = []
		  , i, item;

		for( i=0; i<this.extraFilters.length; i++ ) {
			item = this.extraFilters[ i ];
			extra.push( {
				  id         : item.id
				, label      : item.label
				, icon       : item.icon
				, expression : item.expression
			} );
		}

		return $.extend( {
			  search         : this.searchQuery || ""
			, savedFilterIds : this.activeSaved.slice()
			, extraFilters   : extra
		}, this.getListingFilterState() || {} );
	};

	PresideEverythingBar.prototype._applyAjaxFilterResult = function( item, result ) {
		var applied    = false
		  , extras     = []
		  , listing    = {}
		  , expression, savedIds, i;

		if ( !result || ( result.ok !== true && result.success !== true ) ) {
			return false;
		}

		if ( Object.prototype.hasOwnProperty.call( result, "search" ) ) {
			this.setSearchQuery( result.search );
			applied = true;
		} else if ( Object.prototype.hasOwnProperty.call( result, "searchQuery" ) ) {
			this.setSearchQuery( result.searchQuery );
			applied = true;
		}

		savedIds = result.savedFilterIds || result.savedfilterids;
		if ( $.isArray( savedIds ) && savedIds.length && this._addSavedFilterIds( savedIds ) ) {
			applied = true;
		}

		extras = result.extraFilters || result.extrafilters;
		if ( $.isArray( extras ) && extras.length ) {
			for( i=0; i<extras.length; i++ ) {
				if ( this.addExtraFilter( extras[ i ] ) ) {
					applied = true;
				}
			}
		} else {
			expression = this._normalizeExpression( result.expression );
			if ( expression.length ) {
				this.addExtraFilter( {
					  id         : result.id || item.id
					, label      : result.label || item.label
					, icon       : result.icon || item.chipIcon || item.icon
					, expression : expression
				} );
				applied = true;
			}
		}

		if ( result.columnSearch && typeof result.columnSearch === "object" ) {
			listing.columnSearch = result.columnSearch;
		}
		if ( $.isArray( result.advancedFilter ) ) {
			listing.advancedFilter = result.advancedFilter;
		}
		if ( result.openAdvancedFilter === true || result.openAdvancedFilter === "true" ) {
			listing.openAdvancedFilter = true;
		}

		if ( this.onApplyAjaxResult( listing, result ) ) {
			applied = true;
		}

		if ( applied ) {
			this.renderChips();
		}

		return applied;
	};

	PresideEverythingBar.prototype._addSavedFilterIds = function( ids ) {
		var added = false
		  , self  = this
		  , id, existing;

		$.each( ids || [], function( i, rawId ) {
			id       = String( rawId || "" );
			existing = self.activeSaved.map( String );

			if ( !id.length || existing.indexOf( id ) !== -1 ) {
				return;
			}
			if ( !self._savedById( id ) ) {
				return;
			}
			self.activeSaved.push( id );
			added = true;
		} );

		return added;
	};

	PresideEverythingBar.prototype._pluginError = function( message ) {
		$.gritter.add( {
			  title      : i18n.translateResource( "cms:error.notification.title", { defaultValue : "Error" } )
			, text       : message || t( "cms:datatables.everything.action.error", "That action could not be completed." )
			, class_name : "gritter-error"
			, sticky     : false
		} );
	};

	PresideEverythingBar.prototype.addExtraFilter = function( filter ) {
		var id, expression, extra;

		filter     = filter || {};
		id         = String( filter.id || ( "extra-" + new Date().getTime() ) );
		expression = this._normalizeExpression( filter.expression );
		if ( !expression.length ) {
			return false;
		}

		extra = {
			  id         : id
			, label      : filter.label || id
			, icon       : filter.chipIcon || filter.icon || "magic"
			, expression : expression
		};

		this.extraFilters = this.extraFilters.filter( function( item ){ return String( item.id ) !== id; } );
		this.extraFilters.push( extra );
		this.renderChips();

		return true;
	};

	PresideEverythingBar.prototype.removeExtraFilter = function( id ) {
		var current = String( id );

		this.extraFilters = this.extraFilters.filter( function( item ){ return String( item.id ) !== current; } );
		this.renderChips();
		this.onChange();
	};

	PresideEverythingBar.prototype.clearExtraFilters = function() {
		this.extraFilters = [];
		this.renderChips();
	};

	PresideEverythingBar.prototype.setExtraFilters = function( filters ) {
		var self = this
		  , next = [];

		$.each( filters || [], function( i, filter ) {
			var expression = self._normalizeExpression( filter && filter.expression );
			if ( !expression.length ) {
				return;
			}
			next.push( {
				  id         : String( filter.id || ( "extra-" + i ) )
				, label      : filter.label || filter.id || "Filter"
				, icon       : filter.chipIcon || filter.icon || "magic"
				, expression : expression
			} );
		} );

		this.extraFilters = next;
		this.renderChips();
	};

	PresideEverythingBar.prototype.getExtraFilters = function() {
		return this.extraFilters.slice();
	};

	PresideEverythingBar.prototype.getExtraFilterExpressions = function() {
		var merged = []
		  , i, expression;

		for( i=0; i<this.extraFilters.length; i++ ) {
			expression = this.extraFilters[ i ].expression || [];
			if ( !expression.length ) {
				continue;
			}
			if ( merged.length ) {
				merged.push( "and" );
			}
			if ( expression.length === 1 ) {
				merged.push( expression[ 0 ] );
			} else {
				merged.push( expression );
			}
		}

		return merged;
	};

	PresideEverythingBar.prototype._normalizeExpression = function( expression ) {
		if ( $.isArray( expression ) ) {
			return expression;
		}
		if ( expression && typeof expression === "object" ) {
			return [ expression ];
		}
		if ( typeof expression === "string" && $.trim( expression ).length ) {
			try {
				return this._normalizeExpression( JSON.parse( expression ) );
			} catch( e ) {
				return [];
			}
		}
		return [];
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
