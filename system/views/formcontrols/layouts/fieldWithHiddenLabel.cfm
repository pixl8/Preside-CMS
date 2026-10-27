<!---@feature presideForms--->
<cfscript>
	param name="args.control"  type="string";
	param name="args.label"    type="string";
	param name="args.help"     type="string";
	param name="args.for"      type="string";
	param name="args.error"    type="string";
	param name="args.required" type="boolean";

	hasError = Len( Trim( args.error ) );
	labelId  = "#args.for#-label";
</cfscript>

<cfoutput>
	<div class="form-group form-group-grid<cfif hasError> has-error</cfif>">
		<div>
			<span id="#labelId#" class="sr-only">#args.label#</span>
		</div>
		<div>
			<div class="clearfix" role="group" aria-labelledby="#labelId#">
				#args.control#
			</div>
			<cfif hasError>
				<div for="#args.for#" class="help-block">#args.error#</div>
			</cfif>
		</div>
		<cfif Len( Trim( args.help ) )>
			<div>
				<span class="help-button fa fa-question" data-rel="popover" data-trigger="hover" data-placement="left" data-content="#EncodeForHtmlAttribute( args.help )#" title="#translateResource( 'cms:help.popover.title' )#"></span>
			</div>
		</cfif>
	</div>
</cfoutput>
