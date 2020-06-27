import Parsing

-- expr     ::= term + expr | term
-- term     ::= factor * term | factor
-- factor   ::= (expr) | int

expr = do x <- term
          char '+'
          y <- expr
          return (x+y)
       <|> term

term = do x <- factor
          char '*'
          y <- term
          return (x*y)
       <|> factor

factor = do char '('
            x <- expr
            char ')'
            return x
         <|> int

