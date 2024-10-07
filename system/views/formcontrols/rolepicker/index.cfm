<!---@feature presideForms--->
<cfscript>
	inputName    = args.name         ?: "";
	inputId      = args.id           ?: "";
	inputClass   = args.class        ?: "";
	defaultValue = args.defaultValue ?: "";
	groupedRoles = args.groupedRoles ?: {};
	groups       = structKeyArray( groupedRoles );

	arraySort( groups, "textnocase" );

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	event.include( "/js/admin/specific/rolepicker/"  )
	     .include( "/css/admin/specific/rolepicker/" );

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<div class="preside-role-picker">
		<cfloop array="#groups#" index="group">
			<cfif group neq "__nogroup">
			<div class="collapsible">
				<h4 class="collapsible-header">
					<a href="##" class="collapsible-header-link collapsed" role="button" data-group-id="#group#">
						#translateResource( uri="roles:roleGroup.#group#.title", defaultValue=ucFirst( group ) )#
						<i class="collapsible-header-icon fa fa-fw fa-chevron-right"></i>
					</a>
				</h4>

				<div class="collapsible-content hide group-#group#" data-parent-group-id="#group#">
			</cfif>
					<cfset roles=groupedRoles[ group ] />
					<cfloop array="#roles#" index="role">
						<div class="checkbox role-picker-checkbox">
							<label>
								<input class="#inputClass# ace ace-switch ace-switch-3" name="#inputName#" id="#inputId#-#role#" type="checkbox" value="#HtmlEditFormat( role )#"<cfif ListFindNoCase( value, role )> checked="checked"</cfif> tabindex="#getNextTabIndex()#" #htmlAttributes# />
								<span class="lbl">
									<span class="role-title bigger">
										#translateResource( uri="roles:#role#.title" )#
									</span><br />
									<span class="role-desc">
										#translateResource( uri="roles:#role#.description" )#
									</span>
								</span>
							</label>
						</div>
					</cfloop>
			<cfif group neq "__nogroup">
				</div>
			</div>
			</cfif>
		</cfloop>
	</div>
</cfoutput>
