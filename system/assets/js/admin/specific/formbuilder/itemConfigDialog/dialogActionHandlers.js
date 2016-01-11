( function( $ ){

	var $configForm = $( ".formbuilder-item-config-form" );

	window.isFormBuilderItemConfigValid = function(){
		return $configForm.valid();
	};

	window.getFormBuilderItemConfig = function(){
		return $configForm.serializeObject();
	};

} )( presideJQuery );