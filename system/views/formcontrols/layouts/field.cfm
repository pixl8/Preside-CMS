<cfscript>
	param name="args.control"  type="string";
	param name="args.label"    type="string";
	param name="args.help"     type="string";
	param name="args.for"      type="string";
	param name="args.error"    type="string";
	param name="args.required" type="boolean";

	hasError = Len( Trim( args.error ) );

	help = Len( Trim( args.help ) ) ? HtmlEditFormat( translateResource( uri=args.help, defaultValue=args.help ) ) : "";
</cfscript>

<cfoutput>
	<div class="form-group<cfif hasError> has-error</cfif>">
		<label class="col-sm-2 control-label no-padding-right" for="#args.for#">
			#args.label#
			<cfif args.required>
				<em class="required" role="presentation">
					<sup><i class="fa fa-asterisk"></i></sup>
					<span>#translateResource( "cms:form.control.required.label" )#</span>
				</em>
			</cfif>
			<cfif Len( Trim( help ) )>
				<span class="help-button fa fa-question" data-rel="popover" data-trigger="click" data-placement="right" data-content="#help#" title="#translateResource( 'cms:help.popover.title' )#"></span>
			</cfif>
		</label>

		<div class="col-sm-9">
			<div class="clearfix">
				#args.control#
			</div>
			<cfif hasError>
				<div for="#args.for#" class="help-block">#args.error#</div>
			</cfif>
		</div>
	</div>
</cfoutput>
