( function( $ ){

	var $sortableContainer = $( '#sortable-records' )
	  , $list = $sortableContainer.find( '.dd-list' )
	  , $form = $( '#reorder-form' )
	  , $orderInput = $form.find( "input[name=ordered]")
	  , $resetOrderBtn = $form.find( "#reset-order-btn" )
	  , originalOrder = $list.html()
	  , setOrder;

	setOrder = function(){
		var order = []
		  , $children = $list.find( ".dd-item" );

		$children.each( function(){
			order.push( $(this).data( "id" ) );
		} );

		$orderInput.val( order.join( "," ) ).trigger( 'change' );
	};

	$list.sortable({
  		stop : function( event, ui ) { setOrder(); }
  	} );

	$resetOrderBtn.click( function( e ){
		e.preventDefault();
		$list.html( originalOrder );
		setOrder();
	} );

} )( presideJQuery );