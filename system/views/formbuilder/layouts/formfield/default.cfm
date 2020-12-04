<cfparam name="args.renderedItem" type="string"  />
<cfparam name="args.label"        type="string"  />
<cfparam name="args.id"           type="string"  />
<cfparam name="args.error"        type="string" default=""  />
<cfparam name="args.mandatory"    type="boolean" default="false" />
<cfparam name="args.help"    type="string" default="" />

<cfscript>
	hasError = Len( Trim( args.error ) );
	hasHelp  = Len( Trim( args.help ) );
</cfscript>

<cfoutput>
	<div class="form-group<cfif hasError> has-error</cfif>">
		<label class="col-sm-3 control-label no-padding-right" for="#args.id#">
			#args.label#
			<cfif isTrue( args.mandatory )>
				<em class="required" role="presentation">
					<sup>*</sup>
					<span>#translateResource( "cms:form.control.required.label" )#</span>
				</em>
			</cfif>
		</label>

		<div class="col-sm-9">
			<div class="clearfix">
				#args.renderedItem#
				<cfif hasError>
					<label for="#args.id#" class="error">#args.error#</label>
				</cfif>
				<cfif hasHelp>
					<span class="help-block">#args.help#</span>
				</cfif>
			</div>
		</div>
	</div>
</cfoutput>