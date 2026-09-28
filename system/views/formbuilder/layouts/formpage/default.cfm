<!---@feature formbuilder--->
<cfparam name="args.renderedItems" type="string" default="" />

<cfscript>
	label     = args.label     ?: ( args.configuration.label ?: "" );
	id        = args.id        ?: CreateUUID();
	isSummary = args.isSummary ?: false;
</cfscript>

<cfoutput>
	<div class="formbuilder-page #( isSummary ? 'is-summary' : ''  )#">
		<div class="formbuilder-page-header">
			<div class="formbuilder-page-header-text">
				<h3>#label#</h3>
			</div>

			<cfif isSummary>
				<div class="formbuilder-page-header-buttons">
					<button type="button" class="formbuilder-page-toggler" role="button" data-toggle="collapse" href="##collapsible-#id#" aria-expanded="true" aria-controls="collapsible-#id#">
						<span class="font-icon font-icon-down"></span>
					</button>
				</div>
			</cfif>
		</div>

		<div class="formbuilder-page-content collapse in" id="collapsible-#id#" aria-expanded="true">
			<div class="formbuilder-page-content-wrapper">
				<dl class="dl-horizontal">
					#args.renderedItems#
				</dl>
			</div>
		</div>
	</div>
</cfoutput>