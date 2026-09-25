( function( $ ){

	var t = function( uri, fallback ) {
		return i18n.translateResource( uri, { defaultValue : fallback } );
	};

	window.PresideColumnPicker = function( options ) {
		this.$button  = options.$button;
		this.$panel   = options.$panel;
		this.columns  = options.columns || [];
		this.onChange = options.onChange || function(){};
		this.onReset  = options.onReset || function(){};
		this.onToggle = options.onToggle || function(){};
		this.dirty    = false;

		this._bind();
		this.render();
	};

	PresideColumnPicker.prototype._bind = function() {
		var self = this;

		this.$button.on( "click", function( e ){
			e.preventDefault();
			e.stopPropagation();
			self.toggle();
		} );

		this.$panel.on( "click", function( e ){
			e.stopPropagation();
		} );

		this.$panel.on( "change click", ".listing-column-toggle", function(){
			var $box    = $( this )
			  , field   = $box.attr( "data-field" ) || $box.data( "field" )
			  , visible = $box.is( ":checked" );

			self.columns.forEach( function( col ){
				if ( col.field === field && !col.locked ) {
					col.visible = visible;
				}
			} );
			self.dirty = true;
		} );

		this.$panel.on( "click", ".listing-column-move", function( e ){
			var field = $( this ).closest( ".listing-column-row" ).attr( "data-field" ) || $( this ).closest( ".listing-column-row" ).data( "field" )
			  , dir   = $( this ).data( "dir" );

			e.preventDefault();
			self._move( field, dir );
			self.dirty = true;
			self.render();
		} );

		this.$panel.on( "click", ".listing-column-apply", function( e ){
			e.preventDefault();
			e.stopPropagation();
			e.stopImmediatePropagation();
			self._apply();
		} );

		this.$panel.on( "click", ".listing-column-reset", function( e ){
			e.preventDefault();
			e.stopPropagation();
			self.dirty = false;
			self.close();
			self.onReset();
		} );

		$( document ).on( "click.columnPicker", function( e ){
			if ( !$( e.target ).closest( self.$panel.add( self.$button ) ).length ) {
				self.close();
			}
		} );
	};

	PresideColumnPicker.prototype.toggle = function() {
		if ( this.$panel.hasClass( "hide" ) ) {
			this.$panel.removeClass( "hide" );
			this.$button.addClass( "active" );
			this.onToggle( true );
		} else {
			this.close();
		}
	};

	PresideColumnPicker.prototype.close = function() {
		if ( this.$panel.hasClass( "hide" ) ) {
			return;
		}
		if ( this.dirty ) {
			this._apply();
			return;
		}
		this.$panel.addClass( "hide" );
		this.$button.removeClass( "active" );
		this.onToggle( false );
	};

	PresideColumnPicker.prototype._apply = function() {
		var fields = this.getVisibleFields();

		this.dirty = false;
		this.$panel.addClass( "hide" );
		this.$button.removeClass( "active" );
		this.onToggle( false );
		this.onChange( fields );
	};

	PresideColumnPicker.prototype.setColumns = function( columns ) {
		this.columns = columns || [];
		this.render();
	};

	PresideColumnPicker.prototype.getVisibleFields = function() {
		var ordered = []
		  , byField = {};

		this.columns.forEach( function( col ){
			byField[ col.field ] = col;
		} );

		this.$panel.find( ".listing-column-row" ).each( function(){
			var field = $( this ).attr( "data-field" ) || $( this ).data( "field" )
			  , $box  = $( this ).find( ".listing-column-toggle" )
			  , col   = byField[ field ];

			if ( !col ) {
				return;
			}
			if ( $box.length && !col.locked ) {
				col.visible = $box.is( ":checked" );
			}
			if ( col.visible ) {
				ordered.push( col.field );
			}
		} );

		if ( ordered.length ) {
			return ordered;
		}

		return this.columns.filter( function( col ){
			return col.visible;
		} ).map( function( col ){
			return col.field;
		} );
	};

	PresideColumnPicker.prototype._move = function( field, dir ) {
		var index = -1
		  , swap;

		this.columns.forEach( function( col, i ){
			if ( col.field === field ) {
				index = i;
			}
		} );

		swap = dir === "up" ? index - 1 : index + 1;
		if ( index < 0 || swap < 0 || swap >= this.columns.length ) {
			return;
		}
		if ( this.columns[ index ].locked || this.columns[ swap ].locked ) {
			return;
		}

		this.columns.splice( swap, 0, this.columns.splice( index, 1 )[ 0 ] );
	};

	PresideColumnPicker.prototype.render = function() {
		var html = []
		  , i, col, label;

		for( i=0; i<this.columns.length; i++ ) {
			col   = this.columns[ i ];
			label = $("<div>").text( col.label ).html();
			html.push(
				'<div class="listing-column-row" data-field="' + col.field + '">' +
					'<label class="listing-column-label">' +
						'<input type="checkbox" class="listing-column-toggle no-ace" data-field="' + col.field + '"' + ( col.visible ? ' checked' : '' ) + ( col.locked ? ' disabled' : '' ) + ' />' +
						'<span>' + label + '</span>' +
					'</label>' +
					'<span class="listing-column-order">' +
						'<a href="#" class="listing-column-move" data-dir="up" title="Move up"><i class="fa fa-chevron-up"></i></a>' +
						'<a href="#" class="listing-column-move" data-dir="down" title="Move down"><i class="fa fa-chevron-down"></i></a>' +
					'</span>' +
				'</div>'
			);
		}

		html.push(
			'<div class="listing-column-picker-footer">' +
				'<a href="#" class="listing-column-reset">' + t( "cms:datatables.columns.reset", "Reset to default" ) + '</a>' +
				'<button type="button" class="btn btn-info btn-xs listing-column-apply">' + t( "cms:datatables.columns.apply", "Apply" ) + '</button>' +
			'</div>'
		);
		this.$panel.html( html.join( "" ) );
	};

} )( presideJQuery );
