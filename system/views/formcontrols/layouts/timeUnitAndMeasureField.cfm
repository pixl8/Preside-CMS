<cfscript>
	param name="args.control"  type="string";
	param name="args.label"    type="string";
	param name="args.help"     type="string";
	param name="args.for"      type="string";
	param name="args.error"    type="string";
	param name="args.required" type="boolean";
	param name="args.unit"     type="boolean" default=false;
	param name="args.measure"  type="boolean" default=false;

	hasError = Len( Trim( args.error ) );
</cfscript>

<cfoutput>
	<cfif args.measure>
		<div class="form-group time-unit-and-measure<cfif hasError> has-error</cfif>">
			<label class="col-sm-2 control-label no-padding-right" for="#args.for#">
				#args.label#
				<cfif args.required>
					<em class="required" role="presentation">
						<sup><i class="fa fa-asterisk"></i></sup>
						<span>#translateResource( "cms:form.control.required.label" )#</span>
					</em>
				</cfif>

			</label>

			<div class="col-sm-9">
				<div class="clearfix">
	</cfif>

	#args.control#

	<cfif args.unit>
				</div>
				<cfif hasError>
					<div for="#args.for#" class="help-block">#args.error#</div>
				</cfif>
			</div>
			<cfif Len( Trim( args.help ) )>
				<div class="col-sm-1">
					<span class="help-button fa fa-question" data-rel="popover" data-trigger="hover" data-placement="left" data-content="#HtmlEditFormat( args.help )#" title="#translateResource( 'cms:help.popover.title' )#"></span>
				</div>
			</cfif>
		</div>
	</cfif>
</cfoutput>
