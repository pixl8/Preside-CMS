( function( $ ){

	$.fn.rulesEngineConditionPicker = function(){
		return this.each( function(){
			var $formControl      = $( this )
			  , $builderContainer = $formControl.next( 'div.rules-engine-condition-builder' )
			  , tabIndex          = $formControl.attr( "tabindex" )
			  , savedCondition    = $formControl.val();

			$formControl.removeAttr( "tabindex" ).addClass( "hide" );
			$builderContainer.removeClass( "hide" );
		} );
	};

	$( "textarea.rules-engine-condition-builder" ).rulesEngineConditionPicker();

} )( presideJQuery );