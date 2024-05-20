<!---@feature presideForms--->
<cfscript>
	inputName            = args.name               ?: "";
	inputId              = args.id                 ?: "";
	inputClass           = args.class              ?: "";
	placeholder          = args.placeholder        ?: "";
	defaultValue         = args.defaultValue       ?: "";
	extraClasses         = args.extraClasses       ?: "";
	stylesheets          = args.stylesheets        ?: "";
	widgetCategories     = args.widgetCategories   ?: ( rc.widgetCategories ?: "" );
	linkPickerCategory   = args.linkPickerCategory ?: ( rc.linkPickerCategory ?: "" );
	customDefaultConfigs = !StructIsEmpty( args.customDefaultConfigs ?: {} ) ? SerializeJSON( args.customDefaultConfigs ) : ""
	maxLength            = Val( args.maxLength ?: 0 );

	value = event.getValue( name=inputName, defaultValue=defaultValue );
	if ( !IsSimpleValue( value ) ) {
		value = "";
	}

	value = HtmlEditFormat( value );

	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<textarea id          = "#inputId#"
			  placeholder = "#placeholder#"
			  name        = "#inputName#"
			  class       = "#inputClass# richeditor #extraClasses#"
			  tabindex="#getNextTabIndex()#"
			  <cfif Len( Trim( args.toolbar ?: "" ) )>
				   data-toolbar = "#Trim( args.toolbar )#"
			  </cfif>
			  <cfif Len( Trim( args.customConfig ?: "" ) )>
				  data-custom-config="#Trim( args.customConfig )#"
			  </cfif>
			  <cfif Len( Trim( args.autoParagraph ?: "" ) )>
				  data-auto-paragraph="#isTrue( args.autoParagraph )#"
			  </cfif>
			  <cfif Len( Trim( args.enterMode ?: "" ) )>
				  data-enter-mode="#Trim( args.enterMode )#"
			  </cfif>
			  <cfif Len( Trim( args.stylesheets ?: "" ) )>
				  data-stylesheets="#Trim( args.stylesheets )#"
			  </cfif>
			  <cfif Val( args.width ?: "" )>
				  data-width="#Val( args.width )#"
			  </cfif>
			  <cfif Val( args.minHeight ?: "" )>
				  data-min-height="#Val( args.minHeight )#"
			  </cfif>
			  <cfif Val( args.maxHeight ?: "" )>
				  data-max-height="#Val( args.maxHeight )#"
			  </cfif>
			  <cfif Len( Trim( customDefaultConfigs ?: "" ) )>
				  data-custom-default-configs="#HtmlEditFormat( customDefaultConfigs )#"
			  </cfif>
			  <cfif Len( Trim( widgetCategories ) )>
				  data-widget-categories="#Trim( widgetCategories )#"
			  </cfif>
			  <cfif Len( Trim( linkPickerCategory ) )>
				  data-link-picker-category="#Trim( linkPickerCategory )#"
			  </cfif>
			  #htmlAttributes#
	>#value#</textarea>
</cfoutput>
