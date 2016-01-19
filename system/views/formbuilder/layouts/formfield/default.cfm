<cfparam name="args.renderedItem" type="string"  />
<cfparam name="args.label"        type="string"  />
<cfparam name="args.mandatory"    type="boolean" default="false" />

<cfoutput>
	<div class="form-group">
		<label class="col-sm-2 control-label no-padding-right" for="TODO">
			#args.label#
			<cfif IsTrue( args.mandatory )>
				<em class="required" role="presentation">
					<sup>*</sup>
					<span>#translateResource( "cms:form.control.required.label" )#</span>
				</em>
			</cfif>
		</label>

		<div class="col-sm-9">
			<div class="clearfix">
				#args.renderedItem#
			</div>
		</div>
	</div>
</cfoutput>