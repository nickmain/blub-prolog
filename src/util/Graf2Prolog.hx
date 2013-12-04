package util;

import mind.omnigraffle.plist.PList;
import mind.omnigraffle.GraffleParser;
import mind.omnigraffle.GraffleToProlog;

/**
 * Read an Omnigraffle file (arg0) and write a Prolog theory (arg1)
 */
class Graf2Prolog {

    public static function main() {
		var inPath  = Sys.args()[0];
		var outPath = Sys.args()[1];
		
		var src = sys.io.File.getContent( inPath );
		
		var plist = new PList( Xml.parse( src ) );
        var parser = new GraffleParser( plist );
        var g2p    = new GraffleToProlog();
        parser.writeTo( g2p );
        
        sys.io.File.saveContent( outPath, g2p.toString() );
	}
}
