<!---@feature assetManager--->
<cfscript>
	alignment = args.alignment ?: "";
	imgSrc    = event.buildLink( ( assetId=args.id ?: "" ), derivative=( args.derivative ?: "" ) );
	altText   = HtmlEditFormat( Len( Trim( args.alt_text ?: "" ) ) ? args.alt_text : ( args.title ?: "" ) );
	style     = ListFindNoCase( "left,right", alignment ) ? "float:#LCase( alignment )#;" : "";
	hasFigure = Len( Trim( args.copyright ?: "" ) ) || Len( Trim( args.caption ?: "" ) );
	hasLink   = Len( Trim( args.link ?: ""  ) ) ;

	if( Len( Trim( args.link_asset ?: "" ) )){
		args.link = event.buildLink(  assetId=args.link_asset );
		hasLink   = Len( Trim( args.link ?: ""  ) ) ;
	}

	if( Len( Trim( args.link_page ?: ""  ) )){
		args.link = event.buildLink(  page=args.link_page );
		hasLink   = Len( Trim( args.link ?: ""  ) ) ;
	}

	spacing = {
		  top    = Val( args.spacing_top    ?: ( args.spacing ?: 0 ) )
		, right  = Val( args.spacing_right  ?: ( args.spacing ?: 0 ) )
		, bottom = Val( args.spacing_bottom ?: ( args.spacing ?: 0 ) )
		, left   = Val( args.spacing_left   ?: ( args.spacing ?: 0 ) )
	};

	centerInTable = ListFindNoCase( "auto,center", alignment );

	if ( centerInTable ) {
		style = "margin:#Trim(spacing.top)#px auto #Trim(spacing.bottom)#px auto; display:block;text-align:center;";
	} else {
		style &= "margin:#Trim(spacing.top)#px #Trim(spacing.right)#px #Trim(spacing.bottom)#px #Trim(spacing.left)#px;";
	}

	renderedWidth  = ListLen( args.dimensions ?: "", "x" ) == 2 && Val( ListFirst( args.dimensions, "x" ) ) ? Val( ListFirst( args.dimensions, "x" ) ) : Val( args.width ?: "" );
	figureMaxWidth = renderedWidth ? "max-width:#renderedWidth#px;" : "";
	align          = ListFindNoCase( "left,right", alignment ) ? LCase( alignment ) : "";
</cfscript>

<cfoutput>
	<cfif centerInTable>
		<table width="100%" cellpadding="0" cellspacing="0" border="0">
			<tr>
				<td align="center" style="text-align:center;">
	</cfif>

	<cfif hasFigure>
		<figure style="#style##figureMaxWidth#">
	</cfif>

	<cfif hasLink>
		<a href="#Trim( args.link )#" target="#( args.link_target ?: '_self' )#"<cfif !hasFigure> style="display:block;#style#"</cfif>>
	</cfif>

	<img <cfif Len( align )>align="#align#"</cfif> src="#imgSrc#" alt="#altText#"<cfif centerInTable && renderedWidth> width="#renderedWidth#"</cfif><cfif !hasFigure && !hasLink> style="#style#"</cfif> />

	<cfif hasLink>
		</a>
	</cfif>

	<cfif hasFigure>
			<figcaption>
				<cfif Len( Trim( args.copyright ?: "" ) )>
					<small class="copyright">&copy; #args.copyright#</small>
				</cfif>
				<cfif Len( Trim( args.caption ?: "" ) )>
					#renderContent( data=args.caption, renderer="richeditor" )#
				</cfif>
			</figcaption>
		</figure>
	</cfif>

	<cfif centerInTable>
				</td>
			</tr>
		</table>
	</cfif>
</cfoutput>
