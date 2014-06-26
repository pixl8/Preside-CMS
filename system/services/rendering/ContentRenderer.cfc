component output=false accessors=true {
	property name="viewlet" type="string" default="";
	property name="chain"   type="array"  default=ArrayNew(1);

	public boolean function isChain(){
		return ArrayLen( getChain() );
	}
}