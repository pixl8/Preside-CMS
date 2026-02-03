<!---@feature webflow--->
<cfscript>
	param name="args.control"  type="string";
	param name="args.label"    type="string";
	param name="args.help"     type="string";
	param name="args.for"      type="string";
	param name="args.error"    type="string";
	param name="args.required" type="boolean";

	hasError = Len( Trim( args.error ) );
</cfscript>

<cfoutput>
	<div class="form-group<cfif args.error.len()> has-error</cfif>">
		<div class="row">
			<div class="col-xs-12 col-sm-4 col-lg-3">
				<label class="control-label" for="#args.for#">
					#args.label#
					<cfif IsTrue( args.required )>
						<span class="asterisk" role="presentation">*</span>
					</cfif>
					<cfif Len( Trim( args.help ) )>
						<a href="##" class="font-icon font-icon-tooltip tooltip js-show-tooltip" title="#HtmlEditFormat( args.help )#" data-position="right" ></a>
					</cfif>
				</label>
			</div>

			<div class="col-xs-12 col-sm-8 col-lg-9">
				<div class=" form-field">
					#args.control#
					<cfif args.error.len()>
						<div class="alert alert-message alert-danger error">#args.error#</div>
					</cfif>
				</div>
			</div>
		</div>
	</div>
</cfoutput>
