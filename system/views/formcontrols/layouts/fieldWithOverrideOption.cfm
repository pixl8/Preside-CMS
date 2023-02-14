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
	hasOverride = StructKeyExists( args.savedData, args.name ) || StructKeyExists( rc, args.name );
	event.include( "/js/admin/specific/overrideform/" );
</cfscript>

<cfoutput>
	<div class="form-group<cfif hasError> has-error</cfif> with-override-option">
		<label class="col-sm-1 control-label no-padding-right override-checkbox">
			<input type="checkbox" name="_override_#args.name#" class="ace" <cfif hasOverride> checked</cfif> tabindex="99999" value="1" />
			<span class="lbl"></span>
		</label>
		<label class="col-sm-2 control-label no-padding-right" for="#args.for#">
			#args.label#
		</label>

		<div class="col-sm-8 control">
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
