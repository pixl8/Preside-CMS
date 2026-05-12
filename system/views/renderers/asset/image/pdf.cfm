<!---@feature assetManager--->
<cfscript>
	alignment = args.alignment ?: "";
	imgSrc    = event.buildLink( ( assetId=args.id ?: "" ), derivative=( args.derivative ?: "" ) );
	altText   = HtmlEditFormat( Len( Trim( args.alt_text ?: "" ) ) ? args.alt_text : ( args.title ?: "" ) );
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

	isCenter = ListFindNoCase( "auto,center", alignment );
	isRight  = ( LCase( alignment ) == "right" );

	if ( isCenter ) {
		tableAlign = "center";
		style      = "margin:#Trim(spacing.top)#px auto #Trim(spacing.bottom)#px auto;";
	} else if ( isRight ) {
		tableAlign = "right";
		style      = "display:block; margin:#Trim(spacing.top)#px #Trim(spacing.right)#px #Trim(spacing.bottom)#px auto;";
	} else {
		tableAlign = "left";
		style      = "display:block; margin:#Trim(spacing.top)#px #Trim(spacing.right)#px #Trim(spacing.bottom)#px #Trim(spacing.left)#px;";
	}

	renderedWidth  = ListLen( args.dimensions ?: "", "x" ) == 2 && Val( ListFirst( args.dimensions, "x" ) ) ? Val( ListFirst( args.dimensions, "x" ) ) : Val( args.width ?: "" );
	figureMaxWidth = renderedWidth ? "max-width:#renderedWidth#px;" : "";
</cfscript>

<cfoutput>
	<table width="100%" cellpadding="0" cellspacing="0" border="0">
		<tr>
			<td align="#tableAlign#" style="text-align:#tableAlign#;">
				<cfif isCenter><div style="width:100%; text-align:center;"></cfif>

				<cfif hasFigure>
					<figure style="#style##figureMaxWidth#">
				</cfif>

				<cfif hasLink>
					<a href="#Trim( args.link )#" target="#( args.link_target ?: '_self' )#"<cfif !hasFigure> style="#style#"</cfif>>
				</cfif>

				<img src="#imgSrc#" alt="#altText#"<cfif renderedWidth> width="#renderedWidth#"</cfif><cfif !hasFigure && !hasLink> style="#style#"</cfif> />

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

				<cfif isCenter></div></cfif>
			</td>
		</tr>
	</table>
</cfoutput>
