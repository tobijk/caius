Table with three columns aligned left, center, right:

| a | b | c |
|:--|:-:|--:|
| 1 | 2 | 3 |
|111|222|333|

Table with leading empty column in header row:

|| x | y |
| - | - | - |
| 1 |0.1|0.2|
| 2 |0.2|0.3|

Table with empty header row:

|||
|-|-|-|
|1|2|3

Table with empty header row and leading empty column:

|||
|-|-|-
||2|3

Single column table with leading pipes:

|1
|-
|a

Single column table with pipes alternatingly left and right:

1|
|:-
a|

This table is completely empty:

|||
|-|-|-|
|||

This is a valid table with only a header row:

| a | b | c |
|---|---|---|

Table with only header row and no separator:

| a | b | c |

Table with multiple rows but no header separator:

| a | b | c |
| 1 | 2 | 3 |
| 4 | 5 | 6 |

Table with \| escaped in cells:

| a \| a | b \| b | c \|
|-|-|-
\|1 | 2 | 3 \| 3

Table empty with only one pipe:

|
|-
|

Table with three columns aligned left, center, right randomly indented:

   | a | b | c |    
   |:--|:-:|--:|       
   | 1 | 2 | 3 |   
 |111|222|333|   

Single column table with leading pipes randomly indented:

 |1 
  |-   
   |a  

Single column table with pipes alternatingly left and right randomly indented:

   1| 
  |:-  
 a| 

This table is completely empty and randomly indented:

 |||  
   |-|-|-|      
  |||   

Table empty with only one pipe randomly indented:

 |   
   |-   
  |    
