interface {
	public boolean function match       ( required string path     , required any event ) output=false {}
	public void    function translate   ( required string path     , required any event ) output=false {}
	public boolean function reverseMatch( required struct buildArgs, required any event ) output=false {}
	public string  function build       ( required struct buildArgs, required any event ) output=false {}
}