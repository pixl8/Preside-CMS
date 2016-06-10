<cfscript>
	param name="args.control"   type="string";
	param name="args.label"     type="string";
	param name="args.help"      type="string";
	param name="args.for"       type="string";
	param name="args.error"     type="string";
	param name="args.required"  type="boolean";
	param name="args.name"      type="string";
	param name="args.savedData" type="struct";

	hasError    = Len( Trim( args.error ) );
	hasOverride = args.savedData.keyExists( args.name ) || rc.keyExists( args.name );
</cfscript>

<cfoutput>
	<div class="form-group<cfif hasError> has-error</cfif>">
		<label class="col-sm-1 control-label no-padding-right">
			<input type="checkbox" name="_enable_#args.name#" class="ace" <cfif hasOverride> checked</cfif> />
			<span class="lbl"></span>
		</label>
		<label class="col-sm-2 control-label no-padding-right" for="#args.for#">
			#args.label#
			<cfif args.required>
				<em class="required" role="presentation">
					<sup><i class="fa fa-asterisk"></i></sup>
					<span>#translateResource( "cms:form.control.required.label" )#</span>
				</em>
			</cfif>

		</label>

		<div class="col-sm-8">
			<div class="clearfix">
				<div class="container">
					#args.control#
				</div>
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
</cfoutput>
