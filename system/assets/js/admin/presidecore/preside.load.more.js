( function( $ ){

   $.fn.loadMore = function(){
       return this.each( function(){

           var $link            = $( this )
             , $container       = $link.parents( '.load-more:first' )
             , remoteUrl        = $link.attr( 'data-href' )
             , $targetContainer = $( '#' + $link.attr( 'data-load-more-target' ) ).first()
             , page             = 1
             , preloaded, loadMore, preloadMore, disableLoadMore, enableLoadMore, noMore;


           loadMore = function(){
               if ( preloaded ) {
                   $targetContainer.append( preloaded );
                   preloadMore();
               }
               return false;
           };

           preloadMore = function(){
               page++;
               disableLoadMore();
               $.ajax( {
                     url : remoteUrl + page
                   , success : function( html ){ $.trim( html ).length ? enableLoadMore( html ) : noMore(); }
                   , error : function( error ){ noMore(); }
               } );
           };

           disableLoadMore = function(){
               preloaded = null;
               $container.hide();
           };

           enableLoadMore = function( html ){
               preloaded = $.trim( html );
               $container.removeClass( "hide" );
               $container.fadeIn( 200 );
           };

           noMore = function(){
               $container.remove();
           };
           preloadMore();
           $link.click( function( e ){
               e.preventDefault();
               loadMore();
           } );
       } );
   };

   $( "a.load-more" ).loadMore();
} )( presideJQuery );