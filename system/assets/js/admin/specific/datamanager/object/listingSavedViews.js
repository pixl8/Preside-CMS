( function( $ ){

	var t = function( uri, fallback, data ) {
		return i18n.translateResource( uri, { data : data || [], defaultValue : fallback } );
	};

	window.PresideListingViews = function( options ) {
		this.options          = options || {};
		this.$toolbar         = options.$toolbar;
		this.$root            = this.$toolbar.find( ".listing-views" );
		this.$toggle          = this.$root.find( ".listing-views-toggle" );
		this.$name            = this.$root.find( ".listing-views-name" );
		this.$dirty           = this.$root.find( ".listing-views-dirty" );
		this.$dropdown        = this.$root.find( ".listing-views-dropdown" );
		this.config           = options.config || {};
		this.urls             = options.urls || {};
		this.objectName       = options.objectName || "";
		this.listingKey            = options.listingKey || this.objectName;
		this.listingContextKey     = options.listingContextKey || this.config.listingContextKey || "";
		this.listingContextLabel   = options.listingContextLabel || this.config.listingContextLabel || "";
		this.namedListingContext   = !!( options.namedListingContext || this.config.namedListingContext );
		this.getSnapshot      = options.getSnapshot || function(){ return {}; };
		this.applySnapshot    = options.applySnapshot || function(){};
		this.applyDefault      = options.applyDefault || function(){};
		this.persistActiveView = options.persistActiveView || function(){};
		this.defaultColumnSet = ( this.config.currentColumns || [] ).slice();
		this.defaultSort      = ( options.defaultSort || [] ).slice();
		this.activeId         = "default";
		this.editing          = false;
		this.suppressPrefSave = false;
		this.onLockChange     = options.onLockChange || function(){};

		this._bind();
		this.render();
	};

	PresideListingViews.prototype._bind = function() {
		var self = this;

		this.$toggle.on( "click", function( e ){
			e.preventDefault();
			e.stopPropagation();
			self.toggle();
		} );

		this.$dropdown.on( "click", "[data-view-action]", function( e ){
			e.preventDefault();
			e.stopPropagation();
			self._runAction( $( this ).data( "viewAction" ), $( this ) );
		} );

		$( document ).on( "click.listingViews", function( e ){
			if ( !$( e.target ).closest( self.$root ).length ) {
				self.close();
			}
		} );
	};

	PresideListingViews.prototype.toggle = function() {
		if ( this.isOpen() ) {
			this.close();
		} else {
			this.open();
		}
	};

	PresideListingViews.prototype.isOpen = function() {
		return !this.$dropdown.hasClass( "hide" );
	};

	PresideListingViews.prototype.open = function() {
		this.render();
		this.$dropdown.removeClass( "hide" );
		this.$toggle.attr( "aria-expanded", "true" );
		this.$toolbar.addClass( "is-open" );
	};

	PresideListingViews.prototype.close = function() {
		this.$dropdown.addClass( "hide" );
		this.$toggle.attr( "aria-expanded", "false" );
		if ( !this.$toolbar.find( ".everything-bar-dropdown" ).length || this.$toolbar.find( ".everything-bar-dropdown" ).hasClass( "hide" ) ) {
			this.$toolbar.removeClass( "is-open" );
		}
	};

	PresideListingViews.prototype.restore = function() {
		var stored = this.config.activeView || "default"
		  , view;

		if ( stored && stored !== "default" ) {
			view = this._viewById( stored );
			if ( view ) {
				this.applyNamedView( stored, { skipDraw : true, skipPersist : true } );
				return;
			}
			this.applyDefaultView( { skipDraw : true, skipPersist : true } );
			return;
		}

		this.activeId = "default";
		view = this._resolvedDefaultView();
		if ( view ) {
			this.applySnapshot( view, { skipDraw : true, skipPersist : true } );
		}
		this.render();
	};

	PresideListingViews.prototype.hasResolvedNamedDefault = function() {
		return !!this._resolvedDefaultView();
	};

	PresideListingViews.prototype._resolvedDefaultView = function() {
		var id = this.config.resolvedDefaultViewId || "";
		if ( !id || id === "default" ) {
			return null;
		}
		return this._viewById( id );
	};

	PresideListingViews.prototype.isNamedViewActive = function() {
		return this.activeId !== "default";
	};

	PresideListingViews.prototype.isEditing = function() {
		return !!this.editing;
	};

	PresideListingViews.prototype.filtersAreLocked = function() {
		return this.isNamedViewActive() && !this.editing;
	};

	PresideListingViews.prototype.lockedFilterState = function() {
		var view, filter;

		if ( !this.filtersAreLocked() ) {
			return { savedFilterIds : [], advancedFilter : [], columnSearch : {} };
		}

		view   = this._activeView();
		filter = ( view && view.filterState ) || {};

		return {
			  savedFilterIds : ( filter.savedFilterIds || [] ).slice()
			, advancedFilter : filter.advancedFilter || []
			, columnSearch   : $.extend( true, {}, filter.columnSearch || {} )
		};
	};

	PresideListingViews.prototype.enterEditMode = function() {
		if ( !this.isNamedViewActive() ) {
			return;
		}
		this.editing = true;
		this.render();
		this._syncLock();
	};

	PresideListingViews.prototype.exitEditMode = function() {
		this.editing = false;
		this.render();
		this._syncLock();
	};

	PresideListingViews.prototype._syncLock = function() {
		if ( this.onLockChange ) {
			this.onLockChange();
		}
	};

	PresideListingViews.prototype.shouldSkipColumnPrefSave = function() {
		return this.suppressPrefSave || this.isNamedViewActive();
	};

	PresideListingViews.prototype.selectedColumns = function() {
		return ( this._selectedState().columns || [] ).slice();
	};

	PresideListingViews.prototype.syncDefaultColumns = function( fields ) {
		if ( !this.isNamedViewActive() && $.isArray( fields ) ) {
			this.defaultColumnSet = fields.slice();
		}
		this.refreshDirty();
	};

	PresideListingViews.prototype.refreshDirty = function() {
		this.$dirty.toggleClass( "hide", !this._isDirty() );
		this.$toggle.toggleClass( "is-dirty", this._isDirty() );
		if ( this.isOpen() ) {
			this.render();
		}
	};

	PresideListingViews.prototype.applyNamedView = function( viewId, opts ) {
		var view = this._viewById( viewId );
		if ( !view ) {
			this.applyDefaultView( opts );
			return;
		}

		this.suppressPrefSave = true;
		this.activeId = view.id;
		this.editing  = false;
		this._persist( opts );
		this.applySnapshot( view, opts || {} );
		this.suppressPrefSave = false;
		this.render();
		this._syncLock();
		this.refreshDirty();
	};

	PresideListingViews.prototype.applyDefaultView = function( opts ) {
		var resolved = this._resolvedDefaultView();

		this.suppressPrefSave = true;
		this.activeId = "default";
		this.editing  = false;
		this._persist( opts );
		if ( resolved ) {
			this.applySnapshot( resolved, opts || {} );
		} else {
			this.applyDefault( {
				  columns  : this.defaultColumnSet
				, skipDraw : !!( opts && opts.skipDraw )
			} );
		}
		this.suppressPrefSave = false;
		this.render();
		this._syncLock();
		this.refreshDirty();
	};

	PresideListingViews.prototype.render = function() {
		var html      = []
		  , mine      = []
		  , shared    = []
		  , views     = this.config.savedViews || []
		  , i, view, dirty, canSaveChanges;

		dirty         = this._isDirty();
		canSaveChanges = this.editing && this.isNamedViewActive() && this._activeView() && this._activeView().owner && dirty;

		this.$name.text( this._activeLabel() );
		this.$dirty.toggleClass( "hide", !dirty );
		this.$toggle.toggleClass( "is-dirty", dirty );
		this.$toggle.toggleClass( "is-editing", this.editing );
		this.$root.toggleClass( "is-editing", this.editing );

		html.push( this._itemHtml( "default", this._defaultItemLabel(), this.activeId === "default", false ) );

		for( i=0; i<views.length; i++ ) {
			view = views[ i ];
			if ( view.owner ) {
				mine.push( view );
			} else {
				shared.push( view );
			}
		}

		this._sectionHtml( html, t( "cms:datatables.views.mine", "My views" ), mine );
		this._sectionHtml( html, t( "cms:datatables.views.shared", "Shared with me" ), shared );

		if ( !mine.length && !shared.length ) {
			html.push( '<div class="listing-views-empty">' + t( "cms:datatables.views.empty", "No saved views yet" ) + '</div>' );
		}

		html.push( '<div class="listing-views-actions">' );
		html.push( '<a href="#" class="listing-views-action" data-view-action="save-as">' + t( "cms:datatables.views.saveAs", "Save as view..." ) + '</a>' );
		if ( this.isNamedViewActive() ) {
			html.push( '<a href="#" class="listing-views-action" data-view-action="set-default">' + t( "cms:datatables.views.setAsDefault", "Set as default..." ) + '</a>' );
			if ( this._canClearDefault( this.activeId ) ) {
				html.push( '<a href="#" class="listing-views-action" data-view-action="clear-default">' + t( "cms:datatables.views.clearDefault", "Clear default" ) + '</a>' );
			}
		}
		if ( this.isNamedViewActive() && !this.editing ) {
			html.push( '<a href="#" class="listing-views-action" data-view-action="edit">' + t( "cms:datatables.views.edit", "Edit view" ) + '</a>' );
		}
		if ( this.editing && !dirty ) {
			html.push( '<a href="#" class="listing-views-action" data-view-action="done">' + t( "cms:datatables.views.done", "Done" ) + '</a>' );
		}
		if ( canSaveChanges ) {
			html.push( '<a href="#" class="listing-views-action" data-view-action="save-changes">' + t( "cms:datatables.views.saveChanges", "Save changes" ) + '</a>' );
		}
		if ( this.editing && dirty ) {
			html.push( '<a href="#" class="listing-views-action" data-view-action="discard">' + t( "cms:datatables.views.discard", "Discard changes" ) + '</a>' );
		}
		html.push( '</div>' );

		this.$dropdown.html( html.join( "" ) );
	};

	PresideListingViews.prototype._sectionHtml = function( html, title, views ) {
		var i, view;

		if ( !views.length ) {
			return;
		}

		html.push( '<div class="listing-views-group">' + $("<div>").text( title ).html() + '</div>' );
		for( i=0; i<views.length; i++ ) {
			view = views[ i ];
			html.push( this._itemHtml( view.id, view.label, this.activeId === view.id, view.owner, view.id === ( this.config.resolvedDefaultViewId || "" ) ) );
		}
	};

	PresideListingViews.prototype._itemHtml = function( id, label, selected, owner, isDefault ) {
		var html = '<div class="listing-views-item' + ( selected ? " is-selected" : "" ) + '">' +
			'<a href="#" class="listing-views-item-label" data-view-action="apply" data-view-id="' + $("<div>").text( id ).html() + '">' +
				$("<div>").text( label ).html();

		if ( isDefault ) {
			html += ' <span class="listing-views-default-badge">' + t( "cms:datatables.views.default.badge", "Default" ) + '</span>';
		}

		html += '</a>';

		if ( owner ) {
			html += '<span class="listing-views-item-tools">' +
				'<a href="#" data-view-action="rename" data-view-id="' + $("<div>").text( id ).html() + '" title="' + t( "cms:datatables.views.rename", "Rename" ) + '"><i class="fa fa-pencil"></i></a>' +
				'<a href="#" data-view-action="delete" data-view-id="' + $("<div>").text( id ).html() + '" title="' + t( "cms:datatables.views.delete", "Delete" ) + '"><i class="fa fa-trash"></i></a>' +
			'</span>';
		}

		html += '</div>';
		return html;
	};

	PresideListingViews.prototype._runAction = function( action, $el ) {
		var viewId = String( $el.data( "viewId" ) || "" );

		switch( action ) {
			case "apply":
				this.close();
				if ( viewId === "default" ) {
					this.applyDefaultView();
				} else {
					this.applyNamedView( viewId );
				}
				break;
			case "save-as":
				this.close();
				this._promptSave();
				break;
			case "edit":
				this.close();
				this.enterEditMode();
				break;
			case "done":
				this.close();
				this.exitEditMode();
				break;
			case "save-changes":
				this.close();
				this._saveChanges();
				break;
			case "discard":
				this.close();
				if ( this.activeId === "default" ) {
					this.applyDefaultView();
				} else {
					this.applyNamedView( this.activeId );
				}
				break;
			case "rename":
				this.close();
				this._promptSave( this._viewById( viewId ) );
				break;
			case "set-default":
				this.close();
				this._promptDefault( this.activeId );
				break;
			case "clear-default":
				this.close();
				this._clearDefault( this.activeId );
				break;
			case "delete":
				this.close();
				this._confirmDelete( viewId );
				break;
		}
	};

	PresideListingViews.prototype._promptSave = function( existing ) {
		var self       = this
		  , renaming   = !!( existing && existing.id )
		  , formUrl    = this.urls.form || ""
		  , qs         = []
		  , iframemodal, rawIframe, snapshot, iframeSrc, modalOptions, callbacks;

		if ( !formUrl.length ) {
			return;
		}

		qs.push( "object=" + encodeURIComponent( this.objectName ) );
		qs.push( "listingKey=" + encodeURIComponent( this.listingKey ) );
		if ( this.listingContextKey ) {
			qs.push( "listingContextKey=" + encodeURIComponent( this.listingContextKey ) );
		}
		if ( this.listingContextLabel ) {
			qs.push( "listingContextLabel=" + encodeURIComponent( this.listingContextLabel ) );
		}
		if ( this.namedListingContext ) {
			qs.push( "namedListingContext=true" );
		}
		if ( renaming ) {
			qs.push( "viewId=" + encodeURIComponent( existing.id ) );
		}
		iframeSrc = formUrl + ( formUrl.indexOf( "?" ) >= 0 ? "&" : "?" ) + qs.join( "&" );
		snapshot  = renaming ? null : this.getSnapshot();

		modalOptions = {
			  title     : t( "cms:datatables.views.save.title", "Save listing view" )
			, className : "listing-views-save-dialog"
			, buttons   : {
				  cancel : {
					  label     : t( "cms:cancel.btn", "Cancel" )
					, className : "btn-default"
				  }
				, save : {
					  label     : t( "cms:datatables.views.save.btn", "Save view" )
					, className : "btn-info"
					, callback  : function() {
						if ( rawIframe && rawIframe.listingViewSaveForm ) {
							rawIframe.listingViewSaveForm.submitForm();
							return false;
						}
						return true;
					  }
				  }
			  }
		};
		callbacks = {
			  onLoad : function( iframe ) {
				var $iframeJq, $form;

				rawIframe = iframe;
				iframe.listingViewSaveHost = {
					  close   : function(){ iframemodal.close(); }
					, onSaved : function( view ){ self._onViewSaved( view, renaming ); }
				};

				$iframeJq = iframe.presideJQuery || $;
				$form     = $iframeJq( iframe.document ).find( ".listing-view-save-form" );
				if ( $form.length && snapshot ) {
					self._appendHidden( $form, "columns"             , ( snapshot.columns || [] ).join( "," ) );
					self._appendHidden( $form, "filterState"         , JSON.stringify( snapshot.filterState || {} ) );
					self._appendHidden( $form, "sort"                , JSON.stringify( snapshot.sort || [] ) );
					self._appendHidden( $form, "grantedGridFields"   , ( self.config.grantedColumns || [] ).join( "," ) );
					self._appendHidden( $form, "grantedGridFieldsSig", self.config.grantedColumnsSig || "" );
				}
			  }
			, onShow : function( modal, iframe ) {
				if ( iframe && iframe.listingViewSaveForm ) {
					iframe.listingViewSaveForm.focusForm();
				}
				modal.on( "hidden.bs.modal", function(){
					modal.remove();
				} );
			  }
		};

		iframemodal = new PresideIframeModal( iframeSrc, "100%", "100%", callbacks, modalOptions );
		iframemodal.open();
	};

	PresideListingViews.prototype._appendHidden = function( $form, name, value ) {
		var formEl = $form.get( 0 )
		  , doc    = formEl ? formEl.ownerDocument : document
		  , input  = formEl ? formEl.querySelector( "[name='" + name + "']" ) : null;

		if ( !formEl ) {
			return;
		}
		if ( !input ) {
			input      = doc.createElement( "input" );
			input.type = "hidden";
			input.name = name;
			formEl.appendChild( input );
		}
		input.value = value;
	};

	PresideListingViews.prototype._onViewSaved = function( view, renaming ) {
		if ( !view || !view.id ) {
			return;
		}

		if ( renaming ) {
			this._replaceView( view );
			if ( this.activeId === view.id ) {
				this.render();
			}
			return;
		}

		this.config.savedViews = this.config.savedViews || [];
		this.config.savedViews.push( view );
		this.activeId = view.id;
		this.editing  = false;
		this._persist();
		this.render();
		this._syncLock();
		this.refreshDirty();
	};

	PresideListingViews.prototype._saveChanges = function() {
		var self     = this
		  , view     = this._activeView()
		  , snapshot = this.getSnapshot();

		if ( !view || !view.owner ) {
			return;
		}

		this._post( this.urls.update, {
			  viewId      : view.id
			, label       : view.label
			, columns     : ( snapshot.columns || [] ).join( "," )
			, filterState : JSON.stringify( snapshot.filterState || {} )
			, sort        : JSON.stringify( snapshot.sort || [] )
		}, function( resp ){
			self._replaceView( resp.view || {} );
			self.editing = false;
			self.render();
			self._syncLock();
			self.refreshDirty();
		} );
	};

	PresideListingViews.prototype._confirmDelete = function( viewId ) {
		var self = this
		  , view = this._viewById( viewId );

		if ( !view ) {
			return;
		}

		presideBootbox.confirm(
			t( "cms:datatables.views.delete.confirm", 'Delete the view "{1}"?', [ view.label ] ),
			function( confirmed ) {
				if ( !confirmed ) {
					return;
				}
				self._post( self.urls.delete, { viewId : viewId }, function(){
					self.config.savedViews = ( self.config.savedViews || [] ).filter( function( item ){
						return item.id !== viewId;
					} );
					if ( self.activeId === viewId ) {
						self.applyDefaultView();
					} else {
						self.render();
					}
				}, t( "cms:datatables.views.delete.error", "Your listing view could not be deleted." ) );
			}
		);
	};

	PresideListingViews.prototype._post = function( url, data, success, errorText ) {
		var self = this
		  , payload;

		if ( !url ) {
			return;
		}

		payload = $.extend( {
			  object               : this.objectName
			, listingKey           : this.listingKey
			, listingContextKey    : this.listingContextKey
			, namedListingContext  : this.namedListingContext
			, grantedGridFields    : ( this.config.grantedColumns || [] ).join( "," )
			, grantedGridFieldsSig : this.config.grantedColumnsSig || ""
		}, data || {} );

		$.ajax( {
			  url  : url
			, type : "POST"
			, data : payload
			, success : function( resp ) {
				if ( resp && resp.success ) {
					if ( success ) {
						success( resp );
					}
					return;
				}
				self._error( errorText );
			  }
			, error : function() {
				self._error( errorText );
			  }
		} );
	};

	PresideListingViews.prototype._error = function( errorText ) {
		$.gritter.add({
			  title      : i18n.translateResource( "cms:error.notification.title", { defaultValue : "Error" } )
			, text       : errorText || t( "cms:datatables.views.save.error", "Your listing view could not be saved." )
			, class_name : "gritter-error"
			, sticky     : false
		});
	};

	PresideListingViews.prototype._replaceView = function( view ) {
		var views = this.config.savedViews || []
		  , i;

		if ( !view || !view.id ) {
			return;
		}

		for( i=0; i<views.length; i++ ) {
			if ( views[ i ].id === view.id ) {
				views[ i ] = view;
				return;
			}
		}
		views.push( view );
	};

	PresideListingViews.prototype._viewById = function( id ) {
		var views = this.config.savedViews || []
		  , i;

		for( i=0; i<views.length; i++ ) {
			if ( views[ i ].id === id ) {
				return views[ i ];
			}
		}
		return null;
	};

	PresideListingViews.prototype._activeView = function() {
		if ( this.activeId === "default" ) {
			return null;
		}
		return this._viewById( this.activeId );
	};

	PresideListingViews.prototype._activeLabel = function() {
		var view = this._activeView();
		return view ? view.label : t( "cms:datatables.views.default", "Default" );
	};

	PresideListingViews.prototype._isDirty = function() {
		if ( this.filtersAreLocked() ) {
			return false;
		}
		return this._fingerprint( this.getSnapshot() ) !== this._fingerprint( this._selectedState() );
	};

	PresideListingViews.prototype._selectedState = function() {
		var view     = this._activeView()
		  , resolved = this._resolvedDefaultView();

		if ( view ) {
			return {
				  columns     : view.columns || []
				, filterState : view.filterState || { savedFilterIds : [], advancedFilter : [], columnSearch : {} }
				, sort        : view.sort || []
			};
		}

		if ( resolved ) {
			return {
				  columns     : resolved.columns || []
				, filterState : resolved.filterState || { savedFilterIds : [], advancedFilter : [], columnSearch : {} }
				, sort        : resolved.sort || this.defaultSort.slice()
			};
		}

		return {
			  columns     : this.defaultColumnSet.slice()
			, filterState : { savedFilterIds : [], advancedFilter : [], columnSearch : {} }
			, sort        : this.defaultSort.slice()
		};
	};

	PresideListingViews.prototype._fingerprint = function( state ) {
		var filter = ( state && state.filterState ) || {}
		  , ids    = ( filter.savedFilterIds || [] ).slice().sort();

		return JSON.stringify( {
			  columns         : state && state.columns ? state.columns : []
			, savedFilterIds  : ids
			, advancedFilter  : filter.advancedFilter || []
			, columnSearch    : filter.columnSearch || {}
			, sort            : state && state.sort ? state.sort : []
		} );
	};

	PresideListingViews.prototype._defaultItemLabel = function() {
		var resolved = this._resolvedDefaultView();
		if ( !resolved ) {
			return t( "cms:datatables.views.default", "Default" );
		}
		return t( "cms:datatables.views.default", "Default" ) + " (" + t( "cms:datatables.views.default.using", "using: {1}", [ resolved.label ] ) + ")";
	};

	PresideListingViews.prototype._canClearDefault = function( viewId ) {
		var assignments = this.config.defaultAssignments || {}
		  , groups      = assignments.groups || []
		  , i;

		if ( assignments.personal === viewId ) {
			return true;
		}
		if ( this.config.canShareViews && assignments.everyone === viewId ) {
			return true;
		}
		if ( this.config.canShareViews ) {
			for( i=0; i<groups.length; i++ ) {
				if ( groups[ i ].viewId === viewId ) {
					return true;
				}
			}
		}
		return false;
	};

	PresideListingViews.prototype._applyDefaultAssignment = function( data ) {
		if ( !data ) {
			return;
		}
		this.config.resolvedDefaultViewId = data.resolvedDefaultViewId || "";
		this.config.defaultAssignments    = data.defaultAssignments || {};
		if ( this.activeId === "default" ) {
			this.applyDefaultView();
			return;
		}
		this.render();
	};

	PresideListingViews.prototype._promptDefault = function( viewId ) {
		var self       = this
		  , formUrl    = this.urls.defaultForm || ""
		  , qs         = []
		  , iframemodal, rawIframe, iframeSrc, modalOptions, callbacks;

		if ( !formUrl.length || !viewId ) {
			return;
		}

		qs.push( "object=" + encodeURIComponent( this.objectName ) );
		qs.push( "listingKey=" + encodeURIComponent( this.listingKey ) );
		qs.push( "viewId=" + encodeURIComponent( viewId ) );
		if ( this.listingContextKey ) {
			qs.push( "listingContextKey=" + encodeURIComponent( this.listingContextKey ) );
		}
		if ( this.namedListingContext ) {
			qs.push( "namedListingContext=true" );
		}
		iframeSrc = formUrl + ( formUrl.indexOf( "?" ) >= 0 ? "&" : "?" ) + qs.join( "&" );

		modalOptions = {
			  title     : t( "cms:datatables.views.default.title", "Set as default" )
			, className : "listing-views-save-dialog"
			, buttons   : {
				  cancel : {
					  label     : t( "cms:cancel.btn", "Cancel" )
					, className : "btn-default"
				  }
				, save : {
					  label     : t( "cms:datatables.views.default.btn", "Save default" )
					, className : "btn-info"
					, callback  : function() {
						if ( rawIframe && rawIframe.listingViewDefaultForm ) {
							rawIframe.listingViewDefaultForm.submitForm();
							return false;
						}
						return true;
					  }
				  }
			  }
		};
		callbacks = {
			  onLoad : function( iframe ) {
				rawIframe = iframe;
				iframe.listingViewDefaultHost = {
					  close   : function(){ iframemodal.close(); }
					, onSaved : function( data ){ self._applyDefaultAssignment( data ); }
				};
			  }
			, onShow : function( modal, iframe ) {
				if ( iframe && iframe.listingViewDefaultForm ) {
					iframe.listingViewDefaultForm.focusForm();
				}
				modal.on( "hidden.bs.modal", function(){
					modal.remove();
				} );
			  }
		};

		iframemodal = new PresideIframeModal( iframeSrc, "100%", "100%", callbacks, modalOptions );
		iframemodal.open();
	};

	PresideListingViews.prototype._clearDefault = function( viewId ) {
		var self = this;

		this._post( this.urls.clearDefault, { viewId : viewId }, function( data ){
			self._applyDefaultAssignment( data );
		}, t( "cms:datatables.views.default.clear.error", "That default could not be cleared." ) );
	};

	PresideListingViews.prototype._persist = function( opts ) {
		if ( opts && opts.skipPersist ) {
			return;
		}
		this.persistActiveView( this.activeId );
	};

} )( presideJQuery );
