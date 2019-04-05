/**
 * Quick and dirty jQuery plugin to detect and register listener for state change of a form (from dirty to clean and vice versa)
 * Example useage:
 *
 * $( '#my-form' ).dirtyForm( function( dirty ){
 *     this.find( '[type=submit]' ).prop( "disabled", !dirty );
 * } );
 *
 * @author Dominic Watson, 2013-09-27
 */

( function( $ ){

	$.fn.dirtyForm = function( callback ){
		return this.each( function(){
			var $form     = $( this )
			  , $controls = $form.find( "input,textarea,select" )
			  , isDirty   = false;

			$form.data( "_cleanState", $form.serialize() );
			$form.on( "change keyup click blur", "input,textarea,select", function(){
				var isClean = $form.serialize() === $form.data( "_cleanState" );

				if ( isClean === isDirty ) {
					isDirty = !isClean;
					callback.call( $form, isDirty );
				}
			} );
			$form.on( "uberSelectInit", function(){
				$form.data( "_cleanState", $form.serialize() );
			} );
		} );
	};

	$.fn.dirtyFormDisableToggle = function(){
		return this.each( function(){
			var $form = $( this )
	  		  , $submitButtons = $form.find( "[type=submit]" );

			$form.prop( "disabled", true );
			$submitButtons.prop( "disabled", true );

			$form.dirtyForm( function( dirty ){
				$submitButtons.prop( "disabled", !dirty );
				$form.prop( "disabled", !dirty );
			} );

			$form.submit( function(e){
				if ( $form.prop( "disabled" ) ) {
					e.preventDefault();
				}
			} );
		} );
	};

	$.fn.dirtyFormProtect = function(){
		return this.each( function( i ){
			var $form = $( this )
			  , protectionListener
			  , dirtyRichEditors;

			dirtyRichEditors = function() {
				for( var i in CKEDITOR.instances ) {
					if ( CKEDITOR.instances[ i ].initialdata !== CKEDITOR.instances[ i ].getData() ) {
						return true;
					}
				}
				return false;
			};

			protectionListener = function( e ){
				var message;

				if ( $form.data( "_isDirty" ) || dirtyRichEditors() ) {
					message = i18n.translateResource( "cms:dirty.form.warning" );
					e.returnValue = message;

					return message;
				}
			};
			window.addEventListener( "beforeunload", protectionListener, false );

			$form.dirtyForm( function( dirty ){
				$form.data( "_isDirty", dirty );
			} );
			$form.data( "_isDirty", false );
			$form.submit( function(){
				window.removeEventListener( "beforeunload", protectionListener, false );
			} );

		} );
	};

	$( "form[data-dirty-form*=protect]" ).dirtyFormProtect();
	$( "form[data-dirty-form*=toggleDisable]" ).dirtyFormDisableToggle();
} )( presideJQuery );