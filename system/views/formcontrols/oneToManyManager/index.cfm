<cfparam name="args.linkTitle"  type="string" />
<cfparam name="args.modalTitle" type="string" />
<cfparam name="args.managerUrl" type="string" />

<cfscript>
	htmlAttributes = renderForHTMLAttributes( htmlAttributeNames=( args.htmlAttributeNames ?: "" ), htmlAttributeValues=( args.htmlAttributeValues ?: "" ), htmlAttributePrefix=( args.htmlAttributePrefix ?: "data-" ) );
</cfscript>

<cfoutput>
	<a href="##"
	   class="form-control form-control-no-border one-to-many-manager"
	   data-manager-url="#args.managerUrl#"
	   data-modal-title="#args.modalTitle#"
	   #htmlAttributes#><i class="fa fa-fw fa-external-link"></i> #args.linkTitle#</a>
</cfoutput>
