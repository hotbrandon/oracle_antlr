from antlr4 import *
from grammar.PlSqlLexer import PlSqlLexer
from grammar.PlSqlParser import PlSqlParser
from grammar.PlSqlParserListener import PlSqlParserListener
from loguru import logger

        
class PlSqlListener(PlSqlParserListener):
    def __init__(self):
        self.current_dml_operation = None
        self.current_table = None
        self.in_table_branch = False
        self.ignore_select = False
        self.logs = []

    def enterDelete_statement(self, ctx):
        self.current_dml_operation = 'DELETE'
    
    def enterInsert_statement(self, ctx):
        self.current_dml_operation = 'INSERT'

    def enterSelect_statement(self, ctx:PlSqlParser.Select_statementContext):
        if self.current_dml_operation == 'INSERT':
            self.ignore_select = True

    # Exit a parse tree produced by PlSqlParser#select_statement.
    def exitSelect_statement(self, ctx:PlSqlParser.Select_statementContext):
        self.ignore_select = False

    def enterUpdate_statement(self, ctx):
        self.current_dml_operation = 'UPDATE'

    def enterTableview_name(self, ctx):
        self.in_table_branch = True
        if self.current_dml_operation in ("INSERT","UPDATE","DELETE") and not self.current_table:
            self.current_table = ctx.getText()
            logger.info("enterTableview_name")
            print(f"current_table-> {self.current_table}")

    def exitTableview_name(self, ctx):
        self.in_table_branch = False


    def exitDelete_statement(self, ctx):
        if self.current_table:
            logger.info(f"exitDelete: {self.current_dml_operation} {self.current_table}")
            self.logs.append({"op":self.current_dml_operation,
                             "table": self.current_table,
                             "column":""})
            self.current_table = None
    
    def exitInsert_statement(self, ctx):
        if self.current_table:
            logger.info(f"exitInsert: {self.current_dml_operation} {self.current_table}")
            self.current_table = None
            self.current_dml_operation = None
    
    def exitUpdate_statement(self, ctx):
        if self.current_table:
            print(f'{self.current_dml_operation} statement affecting table {self.current_table}')
            self.current_table = None

    def enterColumn_name(self, ctx:PlSqlParser.Column_nameContext):
        if self.ignore_select:
            # inside a select statement for insert, ignore columns
            return
        
        if self.in_table_branch:
            # this is a table name, don't treat it as a column
            return
        
        if self.current_dml_operation in ("INSERT","UPDATE", "DELETE") and self.current_table:
            self.logs.append({"op":self.current_dml_operation,
                             "table": self.current_table,
                             "column":ctx.getText()})
        print(f"enter column: {ctx.getText()}")

    def exitColumn_name(self, ctx:PlSqlParser.Column_nameContext):
        # print(f"exit column: {ctx.getText()}")
        pass

    # def enterRegular_id(self, ctx:PlSqlParser.Regular_idContext):
        # if self.ignore_select:
        #     # inside a select statement for insert, ignore columns
        #     return
        
        # if self.in_table_branch:
        #     # this is a table name, don't treat it as a column
        #     return
        
        # if self.current_dml_operation in ("INSERT","UPDATE") and self.current_table:
        #     #print(f"current_dml_op:{self.current_dml_operation}")
        #     # print(f"current_table: {self.current_table}")
        #     self.logs.append({"op":self.current_dml_operation,
        #                      "table":{self.current_table},
        #                      "column":ctx.getText()})
        #     # print(f"affected column: {ctx.getText()}")


if __name__ == '__main__':
    input_stream =FileStream('scripts/P_CT_CTAF074.sql', encoding='utf-8')

    lexer = PlSqlLexer(input_stream)
    stream = CommonTokenStream(lexer)
    parser = PlSqlParser(stream)
    tree = parser.sql_script()
    
    walker = ParseTreeWalker()
    listener = PlSqlListener()
    walker.walk(listener, tree)

    # print(listener.logs)
    for log in listener.logs:
        print(f'{log["op"]}\t{log["table"]}\t{log["column"]}')
