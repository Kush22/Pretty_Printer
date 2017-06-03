/*
 *        pretty_printer.y   - This file syntactically analyses a c++ code and if it does not contain any syntax errors 
 *                             produces a well indented target file of the same program.
 *
 * 	  Description        - This file uses pretty_printer.l a file of LEX input scanner. 
 * 			       YACC being a bottom-up parser, the productions are reduced in reverse of right most derivation 
 *			       So the last line of the program is reduced first successively moving to the top
 *			       To display the program  in regular top-down fashion the string of program are concatenated with the strings
 *			       getting reduced later appended to the beginning thus making the body of the program in right order.
 *			       If the productions reach to the head of the start production then the parsing is successful and the concatenated
 *		               body is displayed.
 *
 *	  Submission Details - This file is submitted as Project Assignment : 'CS-602: System Programming & Compiler Design' to respected
 *                             Sir P.D. Sharma, S.G.T.B Khalsa College by Manpreet Kaur (Roll No. 1217) & Kushagra Gupta (Roll No. 1211)
 *			       (6th Semester)
 * 			       Submission Date : 12th April, 2016.
 */
%{
	
 #include <iostream> 
 #include <string>
 #include <map>
 #include <cstdlib>
 #include <cstdio>
 
 using namespace std;

 map <string,string> var;	//symbol table to store the name & type of variables defined ( 2-columns indexed by name )
 FILE *fin, *fout;		//File pointers ( Source File : *fin; Target File : *fout )

 int if_count = 0;         	//count the no of IF's so can be indented appropriately
 int if_block_count = 0;	//to check whether a new if-block has started
 int for_count = 0;		//count the no of FOR's so can be indented appropriately
 int for_block_count = 0;       //to check whether a new for-block has started
 int inblock = -1;		//to check whether we are inside a block ( -1 : since main is also a block but we dont need that to indent )
 char c = ' ';			//block demarcation character

 void yyerror(const char *s);	//overridden function: any error is passed as string to this function and the execution terminated
 extern int yylex();		//invoking the LEX parser to return the scanned lexemes as tokens

%}

				//The tokens returned from LEX needs to be declared with same name with %token label
%token INCLUDE HEADER HEAD_END MAIN TYPE ID RETURN VAL EQUAL CIN IN COUT OUT OP IF ROP CLOSE_BRACE ELSE SEMICOLON OPEN_CURLY CLOSE_CURLY FOR 	    PLUSPLUS MINUSMINUS

%union				//The data types to be used for arributes of production variables are defined as UNION
{
  string * sval;
  int  cval;
  struct			//A structure of attribute values for production symnols that need > 1 attributes
  { 
    string * type;
    string * value;
  } type_value;			//Name of the attribute structure is type_value
}

//==============================//Defining the types for TOKENS
%token <sval> HEADER  		//"headerfile.h"
%token <sval> INCLUDE		// #include <
%token <sval> MAIN		// int main()
%token <sval> TYPE		// int | float | char | void
%token <sval> ID		// variable name
%token <sval> RETURN		// return 0
%token <sval> EQUAL		// = 
%token <type_value> VAL		// value assigned to a variable(ID) (int, float, char)
%token <sval> CIN		// "cin"
%token <sval> IN		// Insertion Operator ( >> )
%token <sval> COUT		// "cout"
%token <sval> OUT		// Extraction Operator ( << )
%token <sval> OP		// Binary Operators ( + | - | * | / | % ) 
%token <sval> IF		// If-statement ("if (")
%token <sval> ROP		// Relational Operators ( < | > | <= | >= | == | != )
%token <sval> CLOSE_BRACE	// )
%token <sval> ELSE		// "else"
%token <sval> OPEN_CURLY	// {
%token <sval> CLOSE_CURLY	// }
%token <sval> FOR		// For-statement ("for (")
%token <sval> PLUSPLUS 		// Increment Operator "++"
%token <sval> MINUSMINUS	// Decrement Operator "--"
%token <sval> SEMICOLON		// ";"

%start prog			// The syntax checking starts from production use head is defined with %start


//==============================//Defining the types for the non-terminals having an attribute value
%type <sval> body		//body is of type 		            : string*
%type <sval> statement		//statement is of type 		            : string*
%type <sval> decl		//decleration (decl) is of type             : string*
%type <sval> initial		//Initialization (initial) is of type       : string*
%type <sval> input		//Input Commands is of type 	            : string*
%type <sval> input1		//Input1 (For cascaded inputs) is of type   : string*
%type <sval> output		//Output Commands is of type 	            : string*
%type <sval> output1		//Output1 (For cascaded outputs) is of type : string*
%type <sval> head_append	//Header (head_append) is of type 	    : string*
%type <sval> arith_expr		//Arithematic Expression is of type 	    : string*
%type <sval> if_else		//If-Else blocks is of type 		    : string*
%type <sval> condition		//Conditional statements is of type 	    : string*
%type <sval> block		//Compound statements (block) is of type    : string*
%type <sval> for_loop		//For-Loop blocks is of type                : string*
%type <sval> increment		//Increment statements (++/--) is of type   : string*
%type <sval> expression		//Arithematic Expression statements of type : string* 

%%

prog		: header main  	// our program is a composed of header files & a main
			{
			   std :: cout << "YAY...Code Successfully Parsed and Indented!!!\n"; 
			}
		;

header		: head_append 
			{
			   for(int i = 0 ; i <(*$1).size(); i++)     // printing out the characters appended in head from earlier productions
			     fprintf(fout,"%c",(*$1)[i]);	     // printing in the output file - fout
			}
        	;

head_append  	: INCLUDE HEADER HEAD_END head_append      	     // Header is composed of ( " #include <"header_file_name.h"> " )
			{
			   *$$ ="#include <" + (*$2)+ ">\n" + (*$4); // Appending the components in attribute of head of production
			}
        	| INCLUDE HEADER HEAD_END			    // For terminating the head_append production	
			{
			   *$$ = "#include <" + (*$2)+ ">\n" ;
			}
   		|	{;}					   //The header part of the program can even be empty so no action to be taken.
		;


main 	: MAIN OPEN_CURLY body RETURN CLOSE_CURLY 
			{
			  fprintf(fout,"%s\n%s  \n",(*$1).c_str(),(*$2).c_str()); // the string in file is printed as c-string
			  for(int i = 0 ; i <(*$3).size(); i++)			  // The body is printed using this loop
			    fprintf(fout,"%c",(*$3)[i]); 
			  fprintf(fout,"\n  %s\n%s",(*$4).c_str(),(*$5).c_str()); // return 0; & '}' are appended at the end of program
			}
	;

body	: statement body	// right recursive definition of body for multiple statements	
			{
			   *$$ = *$1 + *$2;
			}
        | statement		// there can be just one statement
			{
			   *$$ = *$1 ;
			}
        |               {;}    // or no statements at all 
	;

statement : decl		// statement can be a decleration ( e.g. : int a; )
			{ $$ = $1; }
	  | initial		// statement can be a initialization ( e.g : a = 10; ) 
			{ $$ = $1; }
	  | input		// statement can be an input statement ( e.g. : cin >> a; | cin >> a >> b; )
			{ $$ = $1; }
	  | output		// statement can be an output statement ( e.g. : cout << a; | cout << a << b; )
			{ $$ = $1; }
	  | arith_expr		// statement can be an arithematic expression ( e.g. : a = b + c - 4 % d..; )
			{ 
			  $$ = $1;
			  if(if_count != 0) //Indicating a new block is getting started after a statement within if
                            c = ';';	    // this might be the end statement of a block so demarcating by setting 'c'	
			}

          |if_else      {		   			  // statement can be an If-else ( Nested or individual ) block
			  if(inblock != 0 && if_block_count == 0) // when the IF is inside a block ( {} ) but no block is there within
			    if_count--;
		          if(inblock == 0)   		          //when not inside a block we need to decrement if_count when a IF is reduced
			    if_count--;
                          if(if_block_count ==1 && if_count == 0) // when all if's are reduced but due to lookahead an if has been counted
							          // but will not be done afterwards so setting the seen if
                          {
			    if_count = 1;
			    if_block_count = 0;
			  }
			  
			  $$ = $1;	  		          //the value of if_else block is assigned to statement and cascaded up	
			}
       
          |for_loop    {		   			  // statement can be a FOR ( Nested or individual ) block
		         if(inblock != 0 && for_block_count == 0) // when the FOR loop is inside a block ( {} ) but no block is there within
			   for_count--;
		         if(inblock == 0)   		           //when not inside a block we need to decrement for_count when a IF is reduced
			   for_count--;
                         if(for_block_count ==1 && for_count == 0) // when all FOR's are reduced but due to lookahead a FOR has been counted
							           // but will not be done afterwards so setting the seen FOR
                         {
			   for_count = 1;
			   for_block_count = 0;
			 }
			 
			 $$ = $1;	  		           //the value of FOR block is assigned to statement and cascaded up	
			}
	  ;

decl	: TYPE ID SEMICOLON
			{
			  if(var.find(*$2) != var.end())   //variable already defined so prompt an error
			    yyerror("Input Variable Already Defined\n");

                          var[*$2] = *$1;		   //storing the type of variable in symbol-table(var)
                         
			  *$$ = ("  ") + (*$1) + " " + (*$2) + " ;\n";
                           
			  if(if_count != 0)     	   // this might be the end statement of a block so demarcating by setting 'c'
                           c = ';';

			} 
 	;


initial : ID EQUAL VAL SEMICOLON  
			{ 
			   if(var.find(*$1) == var.end() )      // variable not defined previously
			     yyerror("Input Variable Not Defined\n");
                             
			   if( 					// checking LHS and RHS have same type for initialization
			       (var[*$1] == "int" && *($3.type) == "int")    || 
			       (var[*$1] == "char" && *($3.type) == "char")  || 
			       (var[*$1] == "float" && *($3.type) == "float") 
			     )
			     *$$ = ("  ") + (*$1) + (" = ") + (*($3.value)) + " ;\n"  ;
			   else					// type conflict print the error
			     yyerror("Initialisation Error : LHS-RHS type conflict\n"); 
			     
                           if(if_count != 0)  			// this might be the end statement of a block so demarcating by setting 'c'
                           c = ';';
			}
                              
        ;                  

input 	  : CIN input1 SEMICOLON 				// input1 nonterminal handles cascaded inputs
			{ 
			   *$$ = "  cin" + *$2 + " ;\n"; 	// the value is assigned to the head so that concatenated string can be cascaded 
 			   
                           if(if_count != 0)  			// this might be the end statement of a block so demarcating by setting 'c'
                           c = ';';
			}
	  ;

input1 	  : IN ID input1  					// IN = >> so of the form >> a >> b..>>..  
			{
			   if( var.find(*$2) == var.end() )	// the variable is not declared earlier
			     yyerror("Variable in cin has not been declared previously\n");
			   
			   *$$ =" " + *$1 + " " + *$2 + *$3;
			}
     	  | IN ID   		
			{ 
			   if( var.find(*$2) == var.end() )	// the variable is not declared earlier
			     yyerror("Variable in cin has not been declared previously\n");
			  *$$ = " " + *$1 +" " + *$2; 
			}	
      	  ;

output	  : COUT output1 SEMICOLON				// output1 handles cascaded outputs
			{
			   *$$ = "  cout" + *$2 + " ;\n";	// the cout statement is assigned to head so that can be cascaded up
			   
                           if(if_count != 0)  			// this might be the end statement of a block so demarcating by setting 'c' 
                           c = ';';

			}
	  ;

output1   : OUT ID output1  					// OUT = << so of the form << a << b..<<.. 
			{
			   if( var.find(*$2) == var.end() )	// the variable is not declared earlier
			     yyerror("Variable in cout has not been declared previously\n");

			   *$$ = " " + *$1 + " " + *$2 + *$3;
			}
	  | OUT ID
			{
			   if( var.find(*$2) == var.end() )	// the variable is not declared earlier
			     yyerror("Variable in cout has not been declared\n");

			   *$$ = " " + *$1 +" " + *$2; 
			}
	  ;


if_else : IF condition CLOSE_BRACE statement ELSE statement	// IF-else (Type : Both if , else don't have blocks)
                      {
			   for(int i = 0; i < 2*if_count; i++)	// indenting the if and the statements accordingly with if_count
			   {  
			     *$1 = " " + *$1; *$5 = " " + *$5;
                              
			      if ( (*$4)[2*(if_count+1)] != 'i' && (*$4)[2*(if_count+1)+1] != 'f')  //if the following statement is if we need 													    //not increment their space
			        *$4 = " " + *$4; 
			      
			      if ( (*$6)[2*(if_count+1)] != 'i' && (*$6)[2*(if_count+1)+1] != 'f')  // the cascated if statements need not be 
												    // indented 
			        *$6 = " " + *$6;
                           }
				
			   *$$ = *$1 + *$2 + *$3 + "\n" + *$4 + *$5 + "\n" + *$6; 		   // (if (a < b) \n statement(\n already in  
												   // statement) else\n statement appended
				
			}
        | IF condition CLOSE_BRACE statement  			// If-else (Type : Only if, that does not have a block)             
			{  
			   for(int i = 0; i < 2*if_count; i++)	// indenting the if and the statements accordingly with if_count
			    { 
			     *$1 = " " + *$1;
			     
			     if ( (*$4)[2*(if_count+1)] != 'i' && (*$4)[2*(if_count+1)+1] != 'f')  //if the following statement is if we need 													   //not increment their space
			        *$4 = " " + *$4; 	
			    }

			   *$$ = *$1 + *$2 + *$3 + "\n" + *$4; 		  			   // (if (a < b) \n statement appended 

			}
        |IF condition CLOSE_BRACE block				// If-else (Type : Only if, that does not have a block)                          
			{
			   for(int i = 0; i < 2*if_count; i++)	// indenting the if and the statements accordingly with if_count
			     *$1 = " " + *$1; 

			   *$$ = *$1 + *$2 + *$3 + "\n" + *$4;	// (if (a < b)\n { block } appended
			}

        | IF condition CLOSE_BRACE block ELSE block		// If-else (Type : Both if & else have block)
			{  			   
			   for(int i = 0; i < 2*if_count; i++)	// indenting the if and the statements accordingly with if_count
			   {
			     *$1 = " " + *$1;
			     *$5 = " " + *$5;
			   } 

			   *$$ = *$1 + *$2 + *$3 + "\n" + *$4 + *$5+ "\n" + *$6 ; // ( if (a < b)\n {block}(\n already in block) else\n {block}

			}

        | IF condition CLOSE_BRACE block ELSE statement		// If-else (Type : If contains a block and else a statement)
			{  
			   for(int i = 0; i < 2*if_count; i++)	// indenting the if and the statements accordingly with if_count
			   {
			     *$1 = " " + *$1;
			     *$5 = " " + *$5;
                                 
			     if ( (*$6)[2*(if_count+1)] != 'i' && (*$6)[2*(if_count+1)+1] != 'f' ) //in statement part IF : need not be indented
			       *$6 = " " + *$6;
			   } 
                           
			   *$$ = *$1 + *$2 + *$3 + "\n" + *$4 + *$5+ "\n" + *$6 ; // ( if (a < b)\n {block}(\n already there) else\n statement
			   
			}
         | IF condition CLOSE_BRACE statement ELSE block	// If-else (Type : If contains a statement and else a block)
			{  
			   for(int i = 0; i < 2*if_count; i++)	// indenting the if and the statements accordingly with if_count
			   {
			     *$1 = " " + *$1;
			     *$5 = " " + *$5;
                               
			     if ( (*$4)[2*(if_count+1)] != 'i' && (*$4)[2*(if_count+1)+1] != 'f') //in statement part IF : need not be indented
			       *$4 = " " + *$4;
			   } 

			   *$$ = *$1 + *$2 + *$3 + "\n" + *$4 + *$5+ "\n" + *$6 ; // ( if (a < b)\n statement(\n already there) else\n {block}

			}
           ;

block : OPEN_CURLY body CLOSE_CURLY		//Block (Type : { BODY } ) NOTE : uptill now only for if's                 
			{ 
			   string block_statements, open_curly, close_curly, line; //block_statements : contain full body after correct indent
			   int no_line_indent = 0, block_no_indent = 0, block_end_found = 0; 

                           for( int j = 0 ; j < 2 * if_count ; j++)	 //indenting the  { & } accordingly to the block
                           { 
			     line = " " + line;			    	 // line contains each line of body in each iteration
			     open_curly = " " + open_curly ;
			     close_curly = " "+ close_curly;
			   }
	 
			   for(int i = 0 ; i < (*$2).size() ; i++ )
			   {
			     if( (*$2)[i] == 'i' && (*$2)[i+1] == 'f' || (*$2).find(" else ") != -1 ) //if & else are already indented 
			       no_line_indent = 2;			  // taken 2 becos the next statement will be indented already

			     if( (*$2)[i] == '{' ) 			//blocks are already indented - opening of block
			       block_no_indent ++;

			     if( (*$2)[i] == '}' )  			//closing of block but for that iteration it need be there
			       block_end_found = 1;
                               
			     if( (*$2)[i] != '\n' )			//append the characters in line until '\n'
                             	 line += (*$2)[i];
                             else
                             {
                               line += (*$2)[i];			//appending \n to last charater of line
				 
			       if(no_line_indent > 0 || block_no_indent > 0) //they needed no indentation to strip off the extra added
	                         line = line.substr(2*if_count);
				
			       block_statements += line;		//append the line in correct indented body
			       line = "";				
                               for( int j = 0 ; j < 2 * if_count ; j++) //appending the needed space at the beginning of line
                                 line = " " + line;
				
			       no_line_indent--;			//needs to be decreased because one line is taken care of
			       if(block_end_found == 1)			//if block end is found then indentation needs to be decreased
				 block_no_indent--;
                             }
			   }

                           *$$ = open_curly + *$1 + "\n" + block_statements + close_curly + *$3 + "\n"; // { \n body (\n aready) }\n 
			}
           ; 
                                                 

condition : ID ROP ID     					// Condition ( Type : a < b )
			{
			   if(var.find(*$1) == var.end()) 	// variable in condition not defined previously
			     yyerror("Variable in condition Not Defined\n");

			   if(var.find(*$3) == var.end() ) 	// variable in condition not defined previously
			     yyerror("Variable in condition Not Defined\n");

			   *$$ = *$1 + " " + *$2 + " " + *$3;   // ( eg : a(space)<(space)b i.e. a < b ) 
			}
          ;

for_loop : FOR initial condition SEMICOLON increment CLOSE_BRACE statement  // For Block ( for(int i = 0; i < 10; i++) )
			{  
			   for(int i = 0; i < 2*for_count; i++)	// indenting the FOR and the statements accordingly with for_count
			   { 
			     *$1 = " " + *$1;
			     			  	        // FOR's are already indented
			     if ( (*$7)[2*(for_count+1)] != 'f' && (*$7)[2*(for_count+1)+1] != 'o' && (*$7)[2*(for_count+1)+2] != 'r' ) 
			       *$7 = " " + *$7; 		// if statement is not FOR need to be indented accordingly	
			   }

                         string s ; 	// initialization within FOR comes with 2 spaces in beginning so stripping them off
                         for(int i = 2 ; (*$2)[i] != '\n'; i++)
                         s += (*$2)[i];

			   *$$ = *$1 + s+ " " + *$3 +" " +*$4 +" " + *$5 + *$6 +"\n"+ *$7; // for (i = 0 ; i < c; i++)

			}
         ;

increment : ID PLUSPLUS  		// increment-postfix ( type a++ )
			{
			  *$$ = *$1 + *$2;
			}
          | PLUSPLUS ID			// increment-prefix ( type ++a )
			{
			  *$$ = *$1 + *$2;
			}
          | MINUSMINUS ID		// decrement-prefix ( type --a )
			{ 
			  *$$ = *$1 + *$2;
			}
          | ID MINUSMINUS		// decrement-postfix ( type a-- )
			{
			  *$$ = *$1 + *$2;
			}
          ;

arith_expr : ID EQUAL expression SEMICOLON
			{
			  if(var.find(*$1) == var.end() ) 	//variable not defined previously
			     yyerror("Input Variable in Arithematic Expression Not Defined\n");

			  if( var[*$1] != "void" )
			    *$$ = "  " + *$1 + " = " + *$3 + " ;\n";  // type ( a = b + c - 4 ... ;\n) 
			}
	   ;

expression : ID OP expression
			{
			  if( var.find(*$1) == var.end() ) 	//variable not defined previously
			     yyerror("RHS variable in Arithematic Expression Not Defined\n");
			  
			  if( var[*$1] != "void" )
			    *$$ = *$1 + " " + *$2 + " " + *$3;	// type ( (space)id +(expression that already has space) )
			  else
			     yyerror("Invalid Arithematic Operations (void) not allowed"); // the type of operands does not match for operation
			}
	   | VAL OP expression
			{
			  if( *($1.type) != "void" )
			    *$$ = *($1.value) + " " + *$2 + " " + *$3;	// type ( (space)value +(expression that already has space) )
			  else
			     yyerror("Invalid Arithematic Operations (void) not allowed"); // the type of operands does not match for operation
			}

	   | ID OP ID 				//Arithematic Expression ( form: b + c ; )
			{
			   if(var.find(*$1) == var.end() || var.find(*$3) == var.end()) 	//variable not defined previously
			     yyerror("RHS variable in Arithematic Expression Not Defined\n");

			   if( (var[*$1] != "void") && (var[*$3] != "void") )   // cheking the type of variables for compatibility with OP
			     *$$ = *$1 + " " + *$2 + " " + *$3; // type ( (space)id operator id)
			   else
			     yyerror("Invalid Arithematic Operations (void) not allowed"); // the type of operands does not match for operation
			} 
				    
           | ID OP VAL			//Arithematic Expression ( form: b + 5 ; )  
			{
			   if( var.find(*$1) == var.end() ) 	//variable not defined previously
			     yyerror("RHS variable in Arithematic Expression Not Defined\n");

			   if( (var[*$1] != "void") && (*($3.type) != "void") ) // cheking the type of variables for compatibility with OP
			     *$$ = *$1 + " " + *$2 + " " + *($3.value);	// type ( (space)id operator value)
			   else
			     yyerror("Invalid Arithematic Operations");		// the type of operands does not match for operation
			}
 
           | VAL OP ID 			//Arithematic Expression ( form: 5 + b ; )    
			{
			   if(var.find(*$3) == var.end() ) 	//variable not defined previously
			     yyerror("RHS variable in Arithematic Expression Not Defined\n");

			   if( (*($1.type) != "void") && (var[*$3] != "void") ) // cheking the type of variables for compatibility with OP
			     *$$ = *($1.value) + " " + *$2 + " " + *$3;	// type ( (space)value operator id)
			   else
			     yyerror("Invalid Arithematic Operations");		// the type of operands does not match for operation

			} 
           | VAL OP VAL			//Arithematic Expression ( form: 5 + 5 ; )  
			{
			   if( (*($1.type) != "void") && (*($3.type) != "void") ) // cheking the type of variables for compatibility with OP
			     *$$ = *($1.value) + " " + *$2 + " " + *($3.value);	// type ( (space)value operator value)
			   else
			     yyerror("Invalid Arithematic Operations");		  // the type of operands does not match for operation

			} 
        ;

      

%%
  #include <stdio.h>

  extern int yyparse(void);		// decleration of the function that parses and build the parse tree
  extern FILE *yyin;			// input stream pointer

  int main() 
  {   
    fin = fopen("try_file.cpp","r"); 	// opening the source file
    if (!fin)
    {
      std::cout<<"Can't open file!";
      return -1;
    }
  
    fout = fopen("target.cpp", "w");	// opening the target file
    yyin = fin;    			// pointing the input stream pointer to the input file pointer
    do{
      yyparse();			// calling the yyparse function
      }while (!feof(yyin));
    
    fclose(fout);
    return 1;
  }
   
  void yyerror(const char *s)		// function that is called whenever an error is encounted. Prints the message & exits
  {
    std::cout<<"Parse error : " << s <<std::endl;
    exit(0);
  }


