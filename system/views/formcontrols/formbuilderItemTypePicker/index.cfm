<cfscript>
		inputName      = args.name         ?: "";
		inputId        = args.id           ?: "";
		inputClass     = args.class        ?: "";
		defaultValue   = args.defaultValue ?: "";
		extraClasses   = args.extraClasses ?: "";
		categories     = args.categories   ?: [];

		value  = event.getValue( name=inputName, defaultValue=defaultValue );
		if ( not IsSimpleValue( value ) ) {
				value = "";
		}

		value = HtmlEditFormat( value );
		valueFound = false;
</cfscript>

<cfoutput>
	<div class="row">
		<div class="col-md-8">
			<cfloop array="#categories#" index="i" item="category">
				<cfsavecontent variable="categoryOptions">
					<cfloop array="#category.types#" index="n" item="itemType">
						<cfif itemType.isFormField>
							<div class="col-md-4">
								<div class="radio">
									<label>
										<input type="radio"
											 id="#inputId#_#HtmlEditFormat( itemType.id )#"
											 name="#inputName#"
											 value="#HtmlEditFormat( itemType.id )#"
											 class="#inputClass# #extraClasses#"
											 tabindex="#getNextTabIndex()#"
											 <cfif value eq itemType.id>checked</cfif>>
											 <i class="fa fa-fw #itemType.iconClass#"></i> #itemType.title#
									</label>
								</div>
							</div>
						</cfif>
					</cfloop>
				</cfsavecontent>

				<cfif Len( Trim( categoryOptions ) )>
					<h4>#category.title#</h4>
					<div class="row">
						#categoryOptions#
					</div>
					<br>
				</cfif>
			</cfloop>
		</div>
	</div>

	<label for="#inputName#" class="error"></label>
</cfoutput>