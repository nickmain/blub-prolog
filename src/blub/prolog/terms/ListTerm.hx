package blub.prolog.terms;

/**
 * Implemented by terms that could be lists
 */
interface ListTerm extends ValueTerm {
    
	/**
	 * Get the list elements as an array.
	 * @return null if this is not a list
	 */
	public function listToArray():Array<Term>;
}
