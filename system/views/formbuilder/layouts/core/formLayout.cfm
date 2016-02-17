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
					<cfif Len( Trim( args.validationJs ) )>
						if ( typeof jQuery.validator !== 'undefined' ) {

							$form.validate( #args.validationJs# );
							$form.on('submit', function () {

								$.validator.addMethod('filesize', function (value, element, param) {
									if (typeof element.files[0] !== 'undefined') {
										var fileSize = element.files[0].size / 1024;
										var fileSizeInMB = Math.round( (fileSize / 1024) * 100) / 100 ;
										return this.optional(element) || (fileSizeInMB <= param);
									}
									return true;
								}, 'File size must be less than {0} MB');

								$.validator.addMethod("currency", function(value, element, param) {
									var regex = "^[]?([1-9]{1}[0-9]{0,2}(\\,[0-9]{3})*(\\.[0-9]{0,2})?|[1-9]{1}[0-9]{0,}(\\.[0-9]{0,2})?|0(\\.[0-9]{0,2})?|(\\.[0-9]{1,2})?)$";
									regex = new RegExp(regex);
									return regex.test(value);
								}, "Please specify a valid currency");

								$.each($form.find("input[type='file']"), function( key ,value ){
									if($form.find('##' + value.id).length) {
										$form.validate().settings.ignore = ":file:not(input[type='file'])";
										$form.find('##' + value.id).rules("add", {
											"filesize": function ()  {
												return parseInt( $form.find('##maxFileSize_' + value.id).val() );
											}
										});
									}
								});

								if($form.find('.price').length){
									$form.validate().settings.ignore = ":hidden:not(.price)";
									$form.find('.price').each(function(){
										$(this).rules("add", {
											"currency": true,
										});
									});
								}

								if($form.find(".hiddencode").length) {
									$form.validate().settings.ignore = ":hidden:not(##hiddencode)";
									$("input##hiddencode").rules("add", {
										required: function() {
											if(grecaptcha.getResponse() == '') {
												return true;
											} else {
												return false;
											}
			                    		}
									});
			                    }
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