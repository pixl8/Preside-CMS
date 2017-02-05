/**
 * Global actions/viewlets for email center functionality
 *
 */
component extends="preside.system.base.AdminHandler" {

	property name="systemEmailTemplateService" inject="systemEmailTemplateService";
	property name="emailRecipientTypeService"  inject="emailRecipientTypeService";

	private string function emailParamsHelper( event, rc, prc, args={} ) {
		var systemTemplate = Trim( args.systemTemplate ?: "" );
		var recipientType  = Trim( args.recipientType  ?: "" );

		args.params = [];

		if ( systemTemplate.len() ) {
			args.params.append( systemEmailTemplateService.listTemplateParameters( systemTemplate ), true );
		}
		if ( recipientType.len() ) {
			args.params.append( emailRecipientTypeService.listRecipientTypeParameters( recipientType ), true );
		}

		args.params.sort( function( a, b ){
			return  a.required == b.required ? ( a.title > b.title ? 1 : -1 ) : ( a.required ? -1 : 1 );
		} );

		return renderView( view="/admin/emailcenter/_emailParamsHelper", args=args );
	}

}