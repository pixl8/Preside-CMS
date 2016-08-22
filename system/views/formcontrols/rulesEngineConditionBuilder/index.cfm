<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	placeholder  = args.placeholder  ?: "";
	placeholder = HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );
	defaultValue = args.defaultValue ?: "";
	maxLength    = Val( args.maxLength ?: 0 );

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( not IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );

	event.include( "/js/admin/specific/rulesEngineConditionBuilder/"  )
	     .include( "/css/admin/specific/rulesEngineConditionBuilder/" );
</cfscript>

<cfoutput>
	<textarea id="#inputId#" placeholder="#placeholder#" name="#inputName#" class="#inputClass# form-control rules-engine-condition-builder" tabindex="#getNextTabIndex()#">#value#</textarea>
	<div class="rules-engine-condition-builder hide">
		<div class="row">
			<div class="col-md-6">
				<div class="rules-engine-condition-builder-condition-pane form-control">
					<p>TODO: build conditions viewer here :)</p>
				</div>
			</div>
			<div class="col-md-6">
				<div class="rules-engine-condition-builder-expressions-pane">
					<p>TODO: build available expressions pane w/ search here</p>
				</div>
			</div>
		</div>
	</div>
</cfoutput>