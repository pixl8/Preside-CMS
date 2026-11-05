const MARKER = 'Angle <b> "q"';
const ENCODED_BRACKETS = "&lt;b&gt;";
let originalKnownAs = "";

const saveKnownAs = ( knownAs ) => {
	cy.visit( "/admin/editprofile/" );
	cy.get( "input[name=known_as]" ).invoke( "val", knownAs ).trigger( "change" );
	cy.get( "input[name=existing_password]" ).type( "password" );
	cy.get( "form.edit-object-form" ).first().find( "button[type=submit]" ).click();
	cy.get( ".user-info" ).should( "contain", knownAs );
};

describe( "administrator renderer encoding", () => {
	beforeEach( () => {
		cy.session( "superuser", () => {
			cy.superuserAdminLogin();
		} );
	} );

	after( () => {
		if ( !originalKnownAs ) {
			return;
		}

		cy.session( "superuser", () => {
			cy.superuserAdminLogin();
		} );
		saveKnownAs( originalKnownAs );
	} );

	it( "encodes a display name in the admin menu, audit trail and record label", () => {
		cy.visit( "/admin/editprofile/" );
		cy.get( "input[name=known_as]" ).invoke( "val" ).then( ( currentKnownAs ) => {
			originalKnownAs = currentKnownAs;
		} );

		saveKnownAs( MARKER );

		cy.get( ".user-info" ).invoke( "html" ).should( "include", ENCODED_BRACKETS ).and( "not.include", "<b>" );

		cy.visit( "/admin/audittrail/" );
		cy.get( ".page-content", { timeout: 20000 } ).should( "contain", MARKER );
		cy.get( ".page-content" ).invoke( "html" ).should( "include", ENCODED_BRACKETS );
	} );
} );
