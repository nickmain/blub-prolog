package blub.prolog.compiler;

import blub.prolog.Database;
import blub.prolog.Predicate;
import blub.prolog.Clause;
import blub.prolog.terms.Term;
import blub.prolog.terms.ValueTerm;
import blub.prolog.engine.Operations;
import blub.prolog.compiler.Instruction;

/**
 * Translator from Instructions to Operations
 */
class Assembler {

    /** The operation list being built */
    public var operations (default,null):OperationList;

    var db:Database;
	var end:OperationList;
	
	public function new( database:Database ) {
		this.db = database;
	}
	
	/** Translate a list of instructions */
	public function translateList( instructions:InstructionList ) {
		for( i in instructions ) {
			translate( i ); 
		}
	}

    function transOther( instructions:InstructionList ):OperationList {
		var asm = new Assembler( db );
		asm.translateList( instructions );
		return asm.operations;
	}

    /** Translate a single instruction */
    public function translate( i:Instruction ) {
		switch( i ) {
			case call_builtin( functor, args ): add( i, Operations.call_builtin( db, PredicateIndicator.fromString(functor,db.context), args ));
            case call_pred( functor, args ):    add( i, Operations.call_pred( db, PredicateIndicator.fromString(functor,db.context), args ));
            case tail_call( functor, args ):    add( i, Operations.tail_call( db, PredicateIndicator.fromString(functor,db.context), args ));
            case call_clauses( functor ):       add( i, Operations.call_clauses( db, PredicateIndicator.fromString(functor,db.context) ));
			
            case arg_to_env( aIdx, eIdx ): add( i, Operations.arg_to_env( aIdx, eIdx ));
            case set_args( terms ):        add( i, Operations.set_args( terms ));
            case set_arg_values( terms ):  add( i, Operations.set_arg_values( terms ));
            case unify_args( head ):       add( i, Operations.unify_args( head ));
            case unify_arg( index, term ): add( i, Operations.unify_arg( index, term ));
            case choice_point( alt ):      add( i, Operations.choice_point( transOther( alt )));
            case call_nested( code ):      add( i, Operations.call_nested( transOther( code )));
            case new_environment( size ):  add( i, Operations.new_environment( size ));
			
            case push_code_frame:     add( i, Operations.push_code_frame );
            case pop_code_frame:      add( i, Operations.pop_code_frame );
            case succeed:             add( i, Operations.succeed );
            case no_op:               add( i, Operations.no_op );
            case fail:                add( i, Operations.fail );
            case cut:                 add( i, Operations.cut );
            case cut_point:           add( i, Operations.cut_point );
            case log( msg ):          add( i, Operations.log( msg ));
            case call_back( fn ):     add( i, Operations.call_back( fn ));
            case dump:                add( i, Operations.dump );
            case halt:                add( i, Operations.halt );
            case debug_trace( msg ):  add( i, Operations.debug_trace( msg ));
            case halt_count( count ): add( i, Operations.halt_count( count ));
		}
	}
	
	/** Add an operation */
	public function add( i:Instruction, op:Operation ) {
		var asm =
		#if include_asm
		    i;
		#else
		    null;
		#end
		
		if( end == null ) {
			end = { op:op, asm:asm, next:null };
			operations = end;
		}
		else {
			var elem = { op:op, asm:asm, next:null };
			end.next = elem;
			end = elem;
		}
	}
	
	/** Dump a single instruction */
	public static function dumpInstruction( i:Instruction, out:String->Void, ?indent:String = "" ) {
        switch( i ) {
            case call_builtin( functor, args ): out( indent + "call_builtin " + functor + " " + args );
            case call_pred( functor, args ):    out( indent + "call_pred " + functor + " " + args );
            case tail_call( functor, args ):    out( indent + "tail_call " + functor + " " + args );
            case call_clauses( functor ):       out( indent + "call_clauses " + functor );
            
            case arg_to_env( aIdx, eIdx ): out( indent + "arg_to_env " + aIdx + " " + eIdx );
            case set_args( terms ):        out( indent + "set_args " + terms );
            case set_arg_values( terms ):  out( indent + "set_arg_values " + terms );
            case unify_args( head ):       out( indent + "unify_args " + head );
            case unify_arg( index, term ): out( indent + "unify_arg " + index + " " + term );
            
            case choice_point( alt ): {
                out( indent + "choice_point {" );
                dumpAsm( alt, out, indent + ".   " );
                out( indent + "}" );
            }
            
            case call_nested( code ): {
                out( indent + "call_nested {" );
                dumpAsm( code, out, indent + ".   " );
                out( indent + "}" );
            }
            
            case new_environment( size ):  out( indent + "new_environment " + size );
            
            case push_code_frame:     out( indent + "push_code_frame" );
            case pop_code_frame:      out( indent + "pop_code_frame" );
            case succeed:             out( indent + "succeed" );
            case no_op:               out( indent + "no_op" );
            case fail:                out( indent + "fail" );
            case cut:                 out( indent + "cut" );
            case cut_point:           out( indent + "cut_point" );
            case log( msg ):          out( indent + "log '" + msg + "'" );
            case call_back( fn ):     out( indent + "call_back " +  fn );
            case dump:                out( indent + "dump" );
            case halt:                out( indent + "halt" );
            case debug_trace( msg ):  out( indent + "debug_trace '" + msg + "'" );
            case halt_count( count ): out( indent + "halt_count " + count );
        }		
	}
	
	/** Dump a text representation of an InstructionList */
	public static function dumpAsm( instructions:InstructionList, out:String->Void, ?indent:String = "" ) {
        for( i in instructions ) {
            dumpInstruction( i, out, indent );
        }
	}
	
	/** Trace dump an InstructionList */
	public static function traceDump( instructions:InstructionList, prefix:String ) {
		var traceCount = 0;
        var out = function( msg:String ) { 
                      haxe.Log.trace( msg, { methodName  : null,
                                             lineNumber  : (traceCount++),
                                             fileName    : prefix,
                                             customParams: null,
                                             className   : null });
                  };

        dumpAsm( instructions, out );	    
	}
}
