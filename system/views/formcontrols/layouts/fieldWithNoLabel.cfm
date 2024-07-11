<!---@feature presideForms--->
<cfscript>
	param name="args.control"    type="string";
	param name="args.label"      type="string";
	param name="args.help"       type="string";
	param name="args.for"        type="string";
	param name="args.error"      type="string";
	param name="args.required"   type="boolean";
	param name="args.groupClass" type="string";

	hasError = Len( Trim( args.error ) );
</cfscript>

<cfoutput>
	<div class="form-group<cfif hasError> has-error</cfif> #args.groupClass#">
		<div class="col-sm-12">
			<div class="clearfix">
				#args.control#
			</div>
			<cfif hasError>
				<div for="#args.for#" class="help-block">#args.error#</div>
			</cfif>
		</div>
	</div>
</cfoutput>