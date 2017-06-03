%{
#include <iostream>
#include <string>
using namespace std;
#include "y.tab.h"
extern int if_count;
extern int if_block_count;
extern int for_block_count;
extern char c;
extern int inblock;
extern int for_count;
%}

%%

[ \t]*			{;} 

#include[ \t]*\<[ \t]*  { 
			  yylval.sval = new string(yytext);
			  std::cout << "Lex\n";
                          return INCLUDE; 
			}

"++"                    { 
			  yylval.sval = new string(yytext);
			  std::cout << "plusplus\n";
                          return PLUSPLUS; 
			}

"--"                    { 
			  yylval.sval = new string(yytext);
			  std::cout << "minusminus\n";
                          return MINUSMINUS; 
			}

"for"[ \t]*\(          {
                          if(for_count == 0 && for_block_count == 0)
			    for_count = 1;
			  else
			    if( c == ';' && for_count != 0 )
			    {
			      c = ' ';
			      for_block_count = 1;
			    }
			    else
			      for_count++;
			    
			    yylval.sval = new string("for (");
			    std::cout << "for\n";
                            return FOR;
                        }

>[ \n\t]* 		{ return HEAD_END; }   //multiple headers have leading \t & \n's

(stdio|string|conio|iostream|iomanip|time)".h"   { 
			  yylval.sval = new string(yytext);
			  std::cout << "Header\n";
                          return HEADER; 
			}

(int)[ \t]*(main\(\))   {  
			  yylval.sval = new string(yytext);
			  std::cout<<"main "<<yytext<<"\n"; 
			  return MAIN; 
			}

"cin"                   {
			  yylval.sval = new string(yytext);
			  std::cout<<"cin\n"; 
			  return CIN; 
			}

\>\>                    { 
			  yylval.sval = new string(yytext);
			  std::cout<<"<<\n"; 
			  return IN; 
			}
  
"cout"			{
			  yylval.sval = new string(yytext);			  
			  std::cout<<"cout\n";
			  return COUT;
			}

\<\<			{
			  yylval.sval = new string(yytext);
			  std::cout<<"<<\n";
			  return OUT;
			}

"\{"                    {
			  yylval.sval = new string(yytext);
			  inblock++ ;
			  return OPEN_CURLY; 
			}

"\}"                    {
			  yylval.sval = new string(yytext);
			  inblock--;
			  return CLOSE_CURLY;
			}

"\;"                    {
			  yylval.sval = new string(yytext);
			  return SEMICOLON;
			}

"else"                  { 
			  yylval.sval = new string(yytext);
			  std::cout << "else\n";
                          c = ' ';
                          return ELSE;
			}

"\)"                    { c= ' ';
			  yylval.sval = new string(yytext);
			  std::cout << ")\n";
			  return CLOSE_BRACE;
			}
 

"if"[ \t]*\(            {
			  if( if_count == 0 && if_block_count == 0)
			    if_count = 1;
			  else
			    if( c == ';' && if_count != 0 )
			    {
			      c = ' ';
			      if_block_count = 1;
			    }
			    else
			      if_count++;
			    
			    yylval.sval = new string("if (");
			    std::cout << "if\n";
                            return IF;
			}

"\<"|"\>"|"<="|">="|"=="|"!="   {
			  yylval.sval = new string(yytext);
			  std::cout << "operator\n";
			  return ROP;
			}

[0-9]+                  { 
			   yylval.type_value.value = new string(yytext);
                           yylval.type_value.type = new string("int");
			   std::cout << "int\n";
                           return VAL;
			}

[0-9]+\.[0-9]*|[0-9]*\.[0-9]+  {
			  yylval.type_value.value = new string(yytext);
                          yylval.type_value.type = new string("float");
			  std::cout << "float\n";
                          return VAL;
			}     

\'[a-z|A-Z|0-9]\'       {
			  yylval.type_value.value = new string(yytext);
                          yylval.type_value.type = new string("char");
			  std::cout << "char\n";
                          return VAL;
			}

"int"|"char"|"float"|"void"   { 
			  yylval.sval = new string(yytext);
			  std::cout << "int\n";
                          return TYPE;
			}

"="                     { return EQUAL;} 

"+"|"-"|"*"|"/"|"%"	{
			  yylval.sval = new string(yytext);
			  std::cout<<"Operator"<< yytext <<"\n";
			  return OP;
			}

(return)" 0;"           {      
			  yylval.sval = new string(yytext);
			  std::cout<<yytext << "  " << *yylval.sval<< "\n";
                          std::cout<<"return" << "  " << yytext << "\n";
                          return RETURN;
			}

[a-z]+                  { 
			  yylval.sval = new string(yytext);
                          return ID;
			}

.                       {
			  std::cout <<yytext[0]<< "\n";
                          return yytext[0];
			}


%%


