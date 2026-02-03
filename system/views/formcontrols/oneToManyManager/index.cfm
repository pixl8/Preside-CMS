<!---@feature presideForms and admin--->
<cfparam name="args.linkTitle"  type="string" />
<cfparam name="args.modalTitle" type="string" />
<cfparam name="args.managerUrl" type="string" />

<cfscript>
	htmlAttributes = renderHtmlAttributes(
		  attribs      = ( args.attribs      ?: {} )
		, attribNames  = ( args.attribNames  ?: "" )
		, attribValues = ( args.attribValues ?: "" )
		, attribPrefix = ( args.attribPrefix ?: "" )
	);
</cfscript>

<cfoutput>
	<a href="##"
	   class="form-control form-control-no-border one-to-many-manager"
	   data-manager-url="#args.managerUrl#"
	   data-modal-title="#args.modalTitle#"
	   #htmlAttributes#><i class="fa fa-fw fa-external-link"></i> #args.linkTitle#</a>
</cfoutput>
