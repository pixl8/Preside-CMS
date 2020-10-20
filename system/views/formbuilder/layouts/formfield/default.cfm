<cfparam name="args.renderedItem" type="string"  />
<cfparam name="args.label"        type="string"  />
<cfparam name="args.id"           type="string"  />
<cfparam name="args.error"        type="string" default=""  />
<cfparam name="args.mandatory"    type="boolean" default="false" />
<cfparam name="args.help"    type="string" default="" />

<cfscript>
	var hasError = len( trim( args.error ) );
	var hasHelp  = len( trim( args.help ) );
</cfscript>

<cfoutput>
	<div class="form-group<cfif hasError> has-error</cfif>">
		<div class="col-xs-12 col-sm-3">
			<label class="control-label" for="#args.id#">
				#args.label#

				<cfif isTrue( args.mandatory )>
					<em class="required" role="presentation">
						<sup>*</sup>
						<span>#translateResource( "cms:form.control.required.label" )#</span>
					</em>
				</cfif>

				<cfif hasHelp>
					<a class="font-icon-info tooltip-icon" data-toggle="tooltip" title="" data-placement="top" data-original-title="#args.help#"></a>
				</cfif>
			</label>
		</div>

		<div class="col-xs-12 col-sm-9">
			<div class="form-field">
				#args.renderedItem#

				<cfif hasError>
					<label for="#args.id#" class="error">#args.error#</label>
				</cfif>
			</div>
		</div>
	</div>
</cfoutput>