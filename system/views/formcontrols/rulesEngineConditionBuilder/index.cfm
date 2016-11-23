<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	placeholder  = args.placeholder  ?: "";
	placeholder  = HtmlEditFormat( translateResource( uri=placeholder, defaultValue=placeholder ) );
	defaultValue = args.defaultValue ?: "";
	maxLength    = Val( args.maxLength ?: 0 );
	expressions  = args.expressions  ?: [];
	isFilter     = IsTrue( args.isFilter ?: "" ) ? "true" : "false"; // deliberate stringifying of booleans here
	showCount    = IsTrue( args.showCount ?: isFilter );
	object       = args.object ?: "";
	compact      = IsTrue( args.compact ?: "" );

	value  = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );

	if ( isFilter ) {
		conditionPaneTitle     = translateResource( "cms:rulesEngine.filter.builder.condition.pane.title" );
		expressionLibraryTitle = translateResource( "cms:rulesEngine.filter.builder.expressions.pane.title" );
	} else {
		conditionPaneTitle     = translateResource( "cms:rulesEngine.condition.builder.condition.pane.title" );
		expressionLibraryTitle = translateResource( "cms:rulesEngine.condition.builder.expressions.pane.title" );
	}
</cfscript>

<cfoutput>
	<textarea id="#inputId#" placeholder="#placeholder#" name="#inputName#" class="#inputClass# form-control rules-engine-condition-builder" tabindex="#getNextTabIndex()#" data-is-filter="#isFilter#"<cfif isFilter && object.len()> data-object-name="#object#"</cfif>>#value#</textarea>
	<div class="rules-engine-condition-builder hide<cfif compact> compact</cfif>">
		<div class="well">
			<div class="row">
				<div class="col-md-6">
					<h4 class="blue">#conditionPaneTitle#</h4>
					<div class="rules-engine-condition-builder-condition-pane form-control">
						<ul class="list-unstyled rules-engine-condition-builder-rule-list">

						</ul>
					</div>
				</div>
				<div class="col-md-6">
					<h4 class="blue">#expressionLibraryTitle#</h4>
					<div class="rules-engine-condition-builder-expressions-pane">
						<label class="block clearfix">
							<span class="block input-icon input-icon-right">
								<input class="rules-engine-condition-builder-expression-search form-control" placeholder="#HtmlEditFormat( translateResource( 'cms:rulesEngine.expression.search.placeholder' ) )#">
								<i class="fa fa-search fa-fw light-grey"></i>
							</span>
						</label>

						<ul class="list-unstyled rules-engine-condition-builder-expressions-list form-control">
							<cfset currentCategory = "" />
							<cfloop array="#expressions#" item="expression" index="i">
								<cfif expression.category != currentCategory>
									<cfif currentCategory.len()>
											</ul>
										</li>
									</cfif>
									<cfset currentCategory = expression.category />
									<cfset categoryId = "category-" & LCase( Hash( expression.category ) ) />
									<li class="category">
										<a href="##" data-target="###categoryId#" data-toggle="collapse" class="collapsed category-link">
											<i class="fa fa-fw fa-plus-square-o"></i>
											#expression.category#
										</a>
										<ul id="#categoryId#" class="list-unstyled collapse category-expressions">
								</cfif>
								<li class="expression" data-id="#expression.id#">#expression.label#</li>
							</cfloop>
								</ul>
							</li>
						</ul>
					</div>
				</div>
			</div>
			<cfif showCount>
				<div class="row">
					<div class="col-md-12">
						<p class="grey rules-engine-condition-builder-filter-count">#translateResource( uri="cms:rulesEngine.filter.builder.record.count.message", data=[ '<span class="rules-engine-condition-builder-filter-count-count">0</span>'] )#</p>
					</div>
				</div>
			</cfif>
		</div>
	</div>
</cfoutput>