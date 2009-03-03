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

-- | main archy driver
module HelpParser ( help ) where


-- imports

-- local imports
import CalculatorState
import TokenParser
import UnitConverter
import UnitConversionParser


-- | main help parser entry point
help :: CharParser CalcState String
help = unit_info
    <?> "units"


-- | retrieve unit conversion information
unit_info :: CharParser CalcState String
unit_info = reserved "\\units"
            >> optionMaybe parse_unit_type
            >>= \unitType -> return $ retrieve_unit_string unitType


