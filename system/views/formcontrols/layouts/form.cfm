<cfscript>
	tabs               = args.tabs          ?: [];
	content            = args.content       ?: "";
	formName           = args.formName      ?: "";
	validationJs       = args.validationJs  ?: "";
	formId             = args.formId        ?: "";
	tabsPlacement      = args.tabsPlacement ?: "top";

	switch( tabsPlacement ) {
		case "left":
		case "right":
		case "below":
			tabsPlacement = " tabs-#LCase( tabsPlacement )#";
			break;
		case "bottom":
			tabsPlacement = " tabs-below";
			break;
		default:
			tabsPlacement = "";
	}
</cfscript>

<cfoutput>
	<cfif ArrayLen( tabs ) gt 1>
		<div class="tabbable#tabsPlacement#">
			<ul class="nav nav-tabs">
				<cfset active = true />
				<cfloop array="#tabs#" index="tab">
					<li<cfif active> class="active"</cfif>>
						<a data-toggle="tab" href="##tab-#( tab.id ?: '' )#">
							<cfif Len( Trim( tab.iconClass ?: "" ) )>
								<i class="fa fa-fw #tab.iconClass# #( tab.iconColor ?: '' )#"></i>&nbsp;
							</cfif>
							#( tab.title ?: "" )#
						</a>
					</li>
					<cfset active = false />
				</cfloop>
			</ul>

			<div class="tab-content">
	</cfif>

	<input type="hidden" name="$presideform" value="#formName#">

	#content#

	<cfif ArrayLen( tabs ) gt 1>
			</div>
		</div>
	</cfif>

	<cfif Len( Trim( formId ) ) and Len( Trim( validationJs ))>
		<cfsavecontent variable="validationJs">
			( function( $ ){
				$('###formId#').validate( #validationJs# );
			} )( presideJQuery );
		</cfsavecontent>
		<cfset event.includeInlineJs( validationJs ) />
	</cfif>
</cfoutput>