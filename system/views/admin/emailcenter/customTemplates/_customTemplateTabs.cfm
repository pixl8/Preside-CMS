<cfparam name="args.body"                                  default="" />
<cfparam name="args.tab"                                   default="preview" />
<cfparam name="args.canEdit"                type="boolean" default="false" />
<cfparam name="args.canConfigureLayout"     type="boolean" default="false" />
<cfparam name="args.canEditSendOptions"     type="boolean" default="false" />
<cfparam name="args.canConfigureRecipients" type="boolean" default="false" />

<cfscript>
	templateId = rc.id      ?: "";
	version    = rc.version ?: "";
	tabs       = [];

	tabs.append({
		  id     = "preview"
		, icon   = "fa-eye blue"
		, title  = translateResource( "cms:emailcenter.customTemplates.template.tab.preview" )
		, active = ( args.tab == "preview" )
		, link   = ( args.tab == "preview" ) ? "" : event.buildAdminLink( linkTo="emailcenter.customTemplates.preview", queryString="id=#templateId#&version=#version#" )
	});

	if ( args.canEdit ) {
		tabs.append({
			  id     = "edit"
			, icon   = "fa-pencil green"
			, title  = translateResource( "cms:emailcenter.customTemplates.template.tab.edit" )
			, active = ( args.tab == "edit" )
			, link   = ( args.tab == "edit" ) ? "" : event.buildAdminLink( linkTo="emailcenter.customTemplates.edit", queryString="id=#templateId#&version=#version#" )
		});
	}

	if ( args.canConfigureLayout ) {
		tabs.append({
			  id     = "layout"
			, icon   = "fa-code grey"
			, title  = translateResource( "cms:emailcenter.customTemplates.template.tab.layout" )
			, active = ( args.tab == "layout" )
			, link   = ( args.tab == "layout" ) ? "" : event.buildAdminLink( linkTo="emailcenter.customTemplates.configurelayout", queryString="id=" & templateId )
		});
	}

	if ( args.canEditSendOptions ) {
		tabs.append({
			  id     = "sendoptions"
			, icon   = "fa-envelope orange"
			, title  = translateResource( "cms:emailcenter.customTemplates.template.tab.sendOptions" )
			, active = ( args.tab == "sendoptions" )
			, link   = ( args.tab == "sendoptions" ) ? "" : event.buildAdminLink( linkTo="emailcenter.customTemplates.sendoptions", queryString="id=#templateId#" )
		});
	}

	if ( args.canConfigureRecipients ) {
		tabs.append({
			  id     = "recipients"
			, icon   = "fa-users blue"
			, title  = translateResource( "cms:emailcenter.customTemplates.template.tab.recipients" )
			, active = ( args.tab == "recipients" )
			, link   = ( args.tab == "recipients" ) ? "" : event.buildAdminLink( linkTo="emailcenter.customTemplates.recipients", queryString="id=#templateId#" )
		});
	}


</cfscript>

<cfoutput>
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