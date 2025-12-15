/**
 * Exists as a dummy session storage for background threads that need to access the user's details
 * etc. without creating an actual session.
 *
 * @presideService true
 * @singleton      true
 */
component extends="SessionStorage" output=false {

	public any function init() {
		return super.init();
	}

	public any function restore() {
		return;
	}

	public any function persist() {
		return;
	}

	public void function rotate() {
		return;
	}

	public any function getVar( name, default ) output=false {
		var storage = getStorage();
		return storage[ arguments.name ] ?: ( arguments.default ?: "" );
	}

	public any function setVar( name, value ) output=false {
		var storage = getStorage();
		storage[ arguments.name ] = arguments.value;
	}

	public any function deleteVar( name ) output=false {
		var storage = getStorage();

		return StructDelete( storage, arguments.name, true );
	}

	public any function exists( name ) output=false {
		var storage = getStorage();

		return StructKeyExists( storage, arguments.name );
	}

	public any function clearAll() output=false {
		removeStorage();
	}

	public any function getStorage() output=false {
		if ( !StructKeyExists( request, "__dummySessionStorage" ) ) {
			request.__dummySessionStorage = {};
		}

		return request.__dummySessionStorage;
	}

	public any function removeStorage() output=false {
		StructDelete( request, "__dummySessionStorage" );
	}
}