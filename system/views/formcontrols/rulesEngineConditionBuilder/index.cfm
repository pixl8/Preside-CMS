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
					<h4 class="blue">Edit condition</h4>
					<div class="rules-engine-condition-builder-condition-pane form-control">
						<ul class="list-unstyled rules-engine-condition-builder-rule-list">

						</ul>
					</div>
				</div>
				<div class="col-md-6">
					<h4 class="blue">Expression library (drag and drop to add)</h4>
					<div class="rules-engine-condition-builder-expressions-pane">
						<label class="block clearfix">
							<span class="block input-icon input-icon-right">
								<input class="rules-engine-condition-builder-expression-search form-control" placeholder="#HtmlEditFormat( translateResource( 'cms:rulesEngine.expression.search.placeholder' ) )#">
								<i class="fa fa-search fa-fw light-grey"></i>
							</span>
						</label>

						<ul class="list-unstyled rules-engine-condition-builder-expressions-list form-control">
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