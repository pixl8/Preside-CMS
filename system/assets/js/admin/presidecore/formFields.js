( function( $ ){
	$(".object-picker").presideObjectPicker();
	$(".asset-picker").uberAssetSelect();
	$(".image-dimension-picker").imageDimensionPicker();

	$(".auto-slug , .slug-preview").each( function(){
		
		var $this = $(this)
		  , $basedOn = $this.parents("form:first").find("[name='" + $this.data( 'basedOn' ) + "']");
		 
		var ulrPrefix = $this.attr("data-ulrPrefix");
		
		if($this.val() != ''){
			getURLPrefixAndSlug();
		}

		$basedOn.keyup( function(e){
			var slug = $basedOn.val().replace( /\W/g, "-" ).replace( /-+/g, "-" ).toLowerCase();
			$this.val( slug );
			URLslug(slug,ulrPrefix);
		} );

		$this.keyup( function(e){
			var slug = $this.val().replace( /\W/g, "-" ).replace( /-+/g, "-" ).toLowerCase();
			$this.val( slug );
			URLslug(slug,ulrPrefix);
		} );

		$this.parents("form:first").find("select").change(function(){
			getURLPrefixAndSlug();
		});

		function URLslug(slug,prefix){
			$this.nextAll("span").first().text('');
		
			if(slug == 'msg'){
				$this.after("<span style='color:red;'>"+prefix+"</span>");
				if(prefix != ''){
					$this.attr('disabled', true);
				}	
			} else if (slug != ''){
				$this.attr('disabled', false);
				$this.after("<span><b>URL slug</b>: "+window.location.protocol+"//"+prefix + slug+".html</span>");
			}
		}

		function getURLPrefixAndSlug(){
			
			var parentPage = $(".result-container>span.parent~span.title").html();
			var slug = $this.val().replace( /\W/g, "-" ).replace( /-+/g, "-" ).toLowerCase();
			var pageId = $("input[name='id']").val();
			var parentId = $("input[name='parent_page']").val();
			
			$.ajax( buildAjaxLink( 'sitetree.ajaxSlugURL', { title : parentPage, page:pageId,parent:parentId  } ), {
				  method   : "GET"
				, cache    : false
				, success:function(data){
					
					if (data.match(/\/$/) != null) {
						ulrPrefix = location.host + data;
						URLslug(slug,ulrPrefix);
					} else {
						URLslug('msg',data);
					}
				}
			});
		}

	});

	$( 'textarea[class*=autosize]' ).autosize( {append: "\n"} );
	$( 'textarea[class*=limited]' ).each(function() {
		var limit = parseInt($(this).attr('data-maxlength')) || 100;
		$(this).inputlimiter({
			"limit": limit,
			remText: '%n character%s remaining...',
			limitText: 'max allowed : %n.'
		});
	});
	$( 'textarea.richeditor' ).not( '.frontend-container' ).each( function(){
		new PresideRichEditor( this );
	} );

	$('.date-picker')
		.datepicker( { autoclose:true } )
		.next().on( "click", function(){
			$(this).prev().focus();
		});

	$('[data-rel=popover]').popover({container:'body'});

	$('.datetimepicker').datetimepicker({
		icons: {
            time: 'fa fa-clock-o',
            date: 'fa fa-calendar',
            up: 'fa fa-chevron-up',
            down: 'fa fa-chevron-down',
            previous: 'fa fa-chevron-left',
            next: 'fa fa-chevron-right',
            today: 'fa fa-screenshot',
            clear: 'fa fa-trash'
        },

        format: 'YYYY-MM-DD HH:mm',

        sideBySide:true
	});

} )( presideJQuery );