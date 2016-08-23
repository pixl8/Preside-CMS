<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	placeholder  = args.placeholder  ?: "";
	placeholder  = HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );
	defaultValue = args.defaultValue ?: "";
	maxLength    = Val( args.maxLength ?: 0 );
	expressions  = args.expressions  ?: [];

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );
</cfscript>

<cfoutput>
	<textarea id="#inputId#" placeholder="#placeholder#" name="#inputName#" class="#inputClass# form-control rules-engine-condition-builder" tabindex="#getNextTabIndex()#">#value#</textarea>
	<div class="rules-engine-condition-builder hide">
		<div class="well">
			<div class="row">
				<div class="col-md-6">
					<div class="rules-engine-condition-builder-condition-pane form-control">
						<p>TODO: build conditions viewer here :)</p>
					</div>
				</div>
				<div class="col-md-6">
					<div class="rules-engine-condition-builder-expressions-pane">
						<input class="rules-engine-condition-builder-expression-search form-control">
						<ul class="list-unstyled rules-engine-condition-builder-expressions-list">
							<cfloop array="#expressions#" item="expression" index="i">
								<li data-id="#expression.id#">#expression.label#</li>
							</cfloop>
						</ul>
					</div>
				</div>
			</div>
		</div>
	</div>
</cfoutput>