package blub.prolog.io;

/**
 * An abstraction over whatever filesystem is supported in the target
 */
interface FileSystem {

    /** Whether given file exists */
    public function fileExists( name:String ):Bool;
	
	/** Read the entire contents of a text file - null if file does not exist */
	public function readFileContents( name:String ):String;
}
