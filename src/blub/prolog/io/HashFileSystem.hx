package blub.prolog.io;

import haxe.macro.Expr;

/**
 * File system based on a Hash
 */
class HashFileSystem implements FileSystem {

    var files:Map<String,String>;
	
	public funtion new() {
		files = new Map<String,String>();
	}

    /** Whether given file exists */
    public function fileExists( name:String ):Bool {
		return files.exists( name );
	}
    
    /** Read the entire contents of a text file */
    public function readFileContents( name:String ):String {
		return files.get( name );
	}
	
	/** Add a file */
	public function addFile( name:String, contents:String ) {
		files.set( name, contents );
	}
	
	
	/** Macro to create a HashFileSystem and preload all the files in the given dir */
	@:macro public static function preload( dirName:Expr ):Expr {
		//TODO
		return null;	
	}
}
