package mind.prolog.tests;

import mind.util.StringUtil;

class UtilTests extends haxe.unit.TestCase {

    public function testStringUtil() {    
        assertEquals( 0,  StringUtil.compare( "", "" ));
        assertEquals( -1, StringUtil.compare( "", "a" ));
        assertEquals( 1,  StringUtil.compare( "a", "" ));
        assertEquals( 0,  StringUtil.compare( "a", "a" ));
        assertEquals( 0,  StringUtil.compare( "a,sn.dkln    90 ", "a,sn.dkln    90 " ));
        assertTrue  ( StringUtil.compare( "a,sn.dkln    90 ", "a,sn.dkln b  90 " ) < 0 );
        assertTrue  ( StringUtil.compare( "a,sn.dkln b  90 ", "a,sn.dkln    90 " ) > 0 );
    }

}