/**
 * Preside Provider shim for ColdBox 6.0+
 *
 * ColdBox 6.0 renamed get() to $get() on Providers.
 * This shim restores get() for backwards compatibility.
 */
component extends="coldbox.system.ioc.Provider" {

	any function get(){
		return $get();
	}

}
