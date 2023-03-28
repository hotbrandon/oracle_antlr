from antlr4 import *
from grammar.PlSqlLexer import PlSqlLexer
from grammar.PlSqlParser import PlSqlParser
from grammar.PlSqlParserListener import PlSqlParserListener

class PlSqlListener(PlSqlParserListener):
    def __init__(self):
        self.tables = []
        self.columns = []
    def enterQuery_block(self, ctx:PlSqlParser.Query_blockContext):
        pass

    # Exit a parse tree produced by PlSqlParser#query_block.
    def exitQuery_block(self, ctx:PlSqlParser.Query_blockContext):
        pass

    def enterSelected_list(self, ctx:PlSqlParser.Selected_listContext):
        for col in ctx.select_list_elements():
            print(f"column:{col.getText()}")

if __name__ == '__main__':
    input_stream = FileStream('input.sql')
    lexer = PlSqlLexer(input_stream)
    stream = CommonTokenStream(lexer)
    parser = PlSqlParser(stream)
    tree = parser.sql_script()
    
    walker = ParseTreeWalker()
    listener = PlSqlListener()
    walker.walk(listener, tree)
