{-----------------------------------------------------------------
 
  (c) 2008-2009 Markus Dittrich 
 
  This program is free software; you can redistribute it 
  and/or modify it under the terms of the GNU General Public 
  License Version 3 as published by the Free Software Foundation. 
 
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License Version 3 for more details.
 
  You should have received a copy of the GNU General Public 
  License along with this program; if not, write to the Free 
  Software Foundation, Inc., 59 Temple Place - Suite 330, 
  Boston, MA 02111-1307, USA.

--------------------------------------------------------------------}

-- | use QuickCheck to test some properties
module Main where


-- import
import Control.Monad.Writer
import System.Exit


-- local imports
import CalculatorParser
import CalculatorState
import PrettyPrint
import TokenParser


-- | top level main routine 
-- we use the Writer monad to capture the results for all tests 
-- and then examine the results afterward
main :: IO ()
main = do
  let simple = execWriter $ test_driver defaultCalcState simpleTests
  status1 <- examine_output simple

  let failing = execWriter $ test_driver defaultCalcState failingTests
  status2 <- examine_output failing

  let status = status1 && status2
  if status == True then
      exitWith ExitSuccess
    else
      exitWith $ ExitFailure 1
   

-- | helper function for examining the output of a test run
-- prints out the result for each test, collects the number
-- of successes/failures and returns True in case all tests
-- succeeded and False otherwise
examine_output :: [TestResult] -> IO Bool
examine_output = foldM examine_output_h True
                 
  where
    examine_output_h :: Bool -> TestResult -> IO Bool
    examine_output_h acc (TestResult status token target actual) = do
      if status == True then do
          putColorStr     Blue $ "["
          putColorStr    White $ "OK"
          putColorStr     Blue $ "]      "
          putColorStr    Green $ " Successfully evaluated "
          putColorStrLn Yellow $ token
          return $ acc && True
        else do
          putColorStr     Blue $ "["
          putColorStr      Red $ "TROUBLE"
          putColorStr     Blue $ "] "
          putColorStr    Green $ " Failed to evaluate "
          putColorStrLn Yellow $ token
          putColorStrLn  Green $ "\t\texpected : " ++ (convert target)
          putColorStrLn  Green $ "\t\tgot      : " ++ (convert actual)
          return False
    
     where
       convert :: Maybe Double -> String
       convert x = case x of
                     Nothing -> "Nothing"
                     Just a  -> show a


-- | main test routine
test_driver :: CalcState -> [TestCase] -> Writer [TestResult] ()
test_driver state tests = mapM_ test_driver_h tests 

  where
    test_driver_h x = do
      let tok      = fst x
      let expected = snd x
      case runParser calculator state "" tok of
        Left er -> tell [TestResult False tok expected Nothing]
        Right (result, newState) -> examine_result expected result tok
        
        where
          -- NOTE: when we compare target and actual result we
          -- probably need to be more careful and can't use ==
          -- if we are dealing with Doubles!!!
          examine_result :: Maybe Double -> Maybe Double -> String 
                         -> Writer [TestResult] ()
          examine_result target actual token = 
              if target == actual then
                  tell [TestResult True token target actual]
              else 
                  tell [TestResult False token target actual]

 
-- | our test results consist of a bool indicating success
-- or failure, the test token as well as the expected and
-- received result
data TestResult = TestResult { status :: Bool
                             , token  :: String
                             , target :: Maybe Double
                             , actual :: Maybe Double
                             }

defaultResult :: TestResult
defaultResult = TestResult False "" Nothing Nothing


-- | our test tokens are simple pairs of expressions and
-- their result
type TestCase  = (String, Maybe Double)


-- NOTE: For each "run" of test_driver we thread a common 
-- calculator state to be able to test variable assignment
-- and use. Therefore, the order of which tests appear in
-- a [TestCase] may matter if variable definitions are involved.
-- I.e., think twice when changing the order, or keep order
-- dependend and independent sets in different lists 
simpleTests :: [TestCase]
simpleTests = [ simpleTest1, simpleTest2, simpleTest3, simpleTest4
              , simpleTest5, simpleTest6, simpleTest7
              , simpleTest8, simpleTest9, simpleTest10, simpleTest11]

-- list of simple tests
simpleTest1 :: TestCase
simpleTest1 = ("3+4", Just 7.0)

simpleTest2 :: TestCase
simpleTest2 = ("3*3", Just 9.0)

simpleTest3 :: TestCase
simpleTest3 = ("(3*3)+(3*4)", Just 21.0)

simpleTest4 :: TestCase
simpleTest4 = ("(3.0*3.0)+(3.0*4.0)", Just 21.0)

simpleTest5 :: TestCase
simpleTest5 = ("(3+3)*(9+8)", Just 102.0)

simpleTest6 :: TestCase
simpleTest6 = ("(3.0+3.0)*(9.0+8.0)", Just 102.0)

simpleTest7 :: TestCase
simpleTest7 = ("(((((((3.0+3.0)*(9.0+8.0)))))))", Just 102.0)

simpleTest8 :: TestCase
simpleTest8 = ("(((((((3.0+3.0)))))*(((((9.0+8.0)))))))", Just 102.0)

simpleTest9 :: TestCase
simpleTest9 = ("3+3*99.0", Just 300.0)

simpleTest10 :: TestCase
simpleTest10 = ("3+3*8+4*3*2+1*4*3+5", Just 68.0)

simpleTest11 :: TestCase
simpleTest11 = ("(3+3)*(8+4)*3*(2+1)*4*(3+5)", Just 20736.0)



-- a few tests that are failing 
failingTests :: [TestCase]
failingTests = [ failingTest1, failingTest2, failingTest3
               , failingTest4, failingTest5, failingTest6
               , failingTest7, failingTest8, failingTest9
               , failingTest10, failingTest11]

-- list of failing tests
failingTest1 :: TestCase
failingTest1 = ("3+4b", Nothing)

failingTest2 :: TestCase
failingTest2 = ("3*a3", Nothing)

failingTest3 :: TestCase
failingTest3 = ("(3*3)B+(3*4)", Nothing)

failingTest4 :: TestCase
failingTest4 = ("(3.0*3.0)+3.0*4.0)", Nothing)

failingTest5 :: TestCase
failingTest5 = ("(3y3)*(9+8)", Nothing)

failingTest6 :: TestCase
failingTest6 = ("(3.0+3.0)*(9.0+8.0", Nothing)

failingTest7 :: TestCase
failingTest7 = ("(((((((3.0+3.0)*(9.0+8.0))))))", Nothing)

failingTest8 :: TestCase
failingTest8 = ("(((((((3.0+3.0))))*((((((9.0+8.0)))))))", Nothing)

failingTest9 :: TestCase
failingTest9 = ("a3+3*99.0", Nothing)

failingTest10 :: TestCase
failingTest10 = ("3+3*8+4*3++2+1*4*3+5", Nothing)

failingTest11 :: TestCase
failingTest11 = ("(3+3)**(8+4)*3*(2+1)*4*(3+5)", Nothing)