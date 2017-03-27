<cfparam name="args.body"                              default="" />
<cfparam name="args.stats"                             default="" />
<cfparam name="args.tab"                               default="preview" />
<cfparam name="args.canEdit" type="boolean"            default="false" />
<cfparam name="args.canConfigureLayout" type="boolean" default="false" />

<cfscript>
	templateId = rc.template ?: "";
	version    = rc.version  ?: "";
	tabs       = [];

	tabs.append({
		  id     = "preview"
		, icon   = "fa-eye blue"
		, title  = translateResource( "cms:emailcenter.systemTemplates.template.tab.preview" )
		, active = ( args.tab == "preview" )
		, link   = ( args.tab == "preview" ) ? "" : event.buildAdminLink( linkTo="emailcenter.systemTemplates.template", queryString="template=#templateId#&version=#version#" )
	});

	if ( args.canEdit ) {
		tabs.append({
			  id     = "edit"
			, icon   = "fa-pencil green"
			, title  = translateResource( "cms:emailcenter.systemTemplates.template.tab.edit" )
			, active = ( args.tab == "edit" )
			, link   = ( args.tab == "edit" ) ? "" : event.buildAdminLink( linkTo="emailcenter.systemTemplates.edit", queryString="template=#templateId#&version=#version#" )
		});
	}

	if ( args.canConfigureLayout ) {
		tabs.append({
			  id     = "layout"
			, icon   = "fa-code orange"
			, title  = translateResource( "cms:emailcenter.systemTemplates.template.tab.layout" )
			, active = ( args.tab == "layout" )
			, link   = ( args.tab == "layout" ) ? "" : event.buildAdminLink( linkTo="emailcenter.systemTemplates.configurelayout", queryString="template=" & templateId )
		});
	}

	tabs.append({
		  id     = "log"
		, icon   = "fa-list-alt light-grey"
		, title  = translateResource( "cms:emailcenter.systemTemplates.template.tab.log" )
		, active = ( args.tab == "log" )
		, link   = ( args.tab == "log" ) ? "" : event.buildAdminLink( linkTo="emailcenter.systemTemplates.log", queryString="template=#templateId#" )
	});
</cfscript>

<cfoutput>
	#args.stats#
	<div class="tabbable">
		<ul class="nav nav-tabs">
			<cfloop array="#tabs#" index="i" item="tab">
				<li <cfif tab.active>class="active"</cfif>>
					<a href="#tab.link#">
						<i class="fa fa-fw #tab.icon#"></i>&nbsp;
						#tab.title#
					</a>
				</li>
			</cfloop>
		</ul>
		<div class="tab-content">
			<div class="tab-pane active">#args.body#</div>
		</div>
	</div>
</cfoutput>