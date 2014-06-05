/**
 * This file provides UX behaviour for the standard context permissions form
 * This involves hiding and showing of form elements on-click of text lists
 * and ajax saving of said forms
 */

( function( $ ){

	var $contextPermsForm = $( ".manage-context-permissions-form" );

	$contextPermsForm.on( "click", ".edit-col:not(.edit-mode)", function( e ){
		e.preventDefault();

		var $editableContainer = $(this);

		$editableContainer.addClass( "edit-mode" );
	} );

	$contextPermsForm.on( "click", ".close-icon", function( e ){
		e.preventDefault();

		var $editableContainer = $(this).closest( ".edit-col" );

		$editableContainer.removeClass( "edit-mode" );
	} );


} )( presideJQuery );