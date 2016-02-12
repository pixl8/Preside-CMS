<cfparam name="args.renderedItems" type="string" />
<cfparam name="args.id"            type="string" />
<cfparam name="args.validationJs"  type="string" default="" />

<cfoutput>
	<form action="#event.buildLink( linkTo='formbuilder.core.submitAction' )#" id="#args.id#" method="post" enctype="multipart/form-data">
		<cfloop collection="#args#" item="argName">
			<cfif !( [ "id", "validationJs","renderedItems", "context", "layout" ].findNoCase( argName ) ) && IsSimpleValue( args[ argName ] )>
				<input type="hidden" name="#argName#" value="#HtmlEditFormat( args[ argName ] )#">
			</cfif>
		</cfloop>

		#args.renderedItems#
	</form>

	<cfsavecontent variable="formJs">
		( function(){
			if ( typeof jQuery !== 'undefined' ) {
				( function( $ ){
					var $form = $('###args.id#');
					if ( typeof jQuery.validator !== 'undefined' ) {
						$.validator.addMethod('filesize', function (value, element, param) {
							var fileSize = element.files[0].size / 1024;
							var fileSizeInMB = Math.round( (fileSize / 1024) * 100) / 100 ;
							return this.optional(element) || (fileSizeInMB <= param)
						}, 'File size must be less than {0} MB');

						if($form.find("input[type='file']").length) {
							$form.validate().settings.ignore = ":file:not(input[type=file])";
							$("input[type='file']").rules("add", {
								"filesize": function ()  {
								return parseInt( $("input[name='maxFileSize']").val() );
								},
								messages:{filesize:"File size must be less than {0} MB"}
							});
						}
					}
					<cfif Len( Trim( args.validationJs ) )>
						if ( typeof jQuery.validator !== 'undefined' ) {
							$form.validate( #args.validationJs# );
							$form.on('submit', function () {
								if($form.find(".hiddencode").length) {
									$form.validate().settings.ignore = ":hidden:not(##hiddencode)";
									$("input##hiddencode").rules("add", {required: function() {
			                           if(grecaptcha.getResponse() == '') {
			                               return true;
			                           } else {
			                               return false;
			                           }
			                    	}});
			                    });
							});
						}
					</cfif>
					$form.presideFormBuilderForm();
				} )( jQuery );
			}
		} )();
	</cfsavecontent>
	<cfset event.includeInlineJs( formJs ) />
</cfoutput>