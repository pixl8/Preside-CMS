/**
 * This file provides UX behaviour for the standard context permissions form
 * This involves hiding and showing of form elements on-click of text lists
 * and ajax saving of said forms
 */

( function( $ ){

	var $contextPermsTable = $( ".manage-context-permissions" );

	$contextPermsTable.on( "click", ".edit-col:not(.edit-mode)", function( e ){
		e.preventDefault();

		var $editableContainer = $(this);

		$editableContainer.addClass( "edit-mode" );
	} );

	$contextPermsTable.on( "click", ".context-permission-form-cancel-button", function( e ){
		e.preventDefault();

		var $editableContainer = $(this).closest( ".edit-col" );

		$editableContainer.removeClass( "edit-mode" );
	} );


} )( presideJQuery );