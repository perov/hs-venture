{
module VentureGrammar(parse) where

import qualified VentureTokens as T
import Language

}

%name parseHelp
%tokentype { T.Token }
%error { parseError }
%monad { T.Alex }
%lexer { T.tokenize } { T.Eof }

%token
  '('  { T.Open }
  ')'  { T.Close }
  int  { T.Int $$ }
  flo  { T.Float $$ }
  lam  { T.Symbol "lambda" }
  quo  { T.Symbol "quote" }
  sym  { T.Symbol $$ }

%%

Exp : sym  { Var $1 }
    | int  { Datum $ Number $ fromInteger $1 }
    | flo  { Datum $ Number $1 }
    | '(' quo Exp ')' { Datum $ exp_to_value $3 } -- Or do I want a separate "datum" grammar?
    | '(' Exp Exps ')' { App $2 (reverse $3) }
    | '(' lam '(' Syms ')' Exp ')' { Lam (reverse $4) $6 }

Exps :  { [] }
     | Exps Exp { $2 : $1 }

Syms : { [] }
     | Syms sym { $2 : $1 }

{

-- TODO: Putting sexp-quote into this grammar sucks.  Options:
-- - Add a (quote <exp>) rule whose semantic action downgrades an
--   expression to a value (this is what I did here)
-- - Add a separate segment to the grammar to parse the inside of a quote differently
-- - Eliminate parsing for expressions entirely, and write a converter
--   from list structure that detects keywords.
exp_to_value (Datum val) = val
exp_to_value (Var name) = Symbol name
exp_to_value (App op opands) = List $ map exp_to_value (op:opands)
exp_to_value (Lam formals body) = List [Symbol "lambda", List (map Symbol formals), exp_to_value body]

parseError :: T.Token -> T.Alex a
parseError t = T.Alex (\T.AlexState {T.alex_pos = (T.AlexPn _ line col)} -> Left $ "Parse error at " ++ show line ++ ":" ++ show col ++ " on token " ++ show t)

-- parse :: String -> Exp v -- except v is constrained
parse :: (Fractional num) => String -> Exp (Value proc num)
parse s = case T.runAlex s $ parseHelp of
            Left err -> error $ "Error parsing " ++ s ++"\n" ++ err
            Right e -> fmap (fmap realToFrac) e
}
