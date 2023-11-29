(*COSC 3410 - Project 8
 @author [Viviana Garcia, Andrew Allen]
 Instructor [Dennis Brylow]
 TA-BOT:MAILTO [viviana.garcia@marquette.edu, andrew.allen@marquette.edu]*)

(*part a: *)

| circle1 circle2 |
circle1 := Circle new
circle2 := Circle new
circle1 location: (Point x: 0 y: 0)
circle2 location: (circle1 location adjustPoint: circle1 radius to: 'right')

Display draw: circle1
Display draw: circle2



(*part b: *)
| square1 square2 |
square1 := Square new size: 100
square2 := Square new size: 50
square2 location: (square1 location adjustPoint: (Point x: (square1 size // 2) - (square2 size // 2) y: (square1 size // 2) - (square2 size // 2)) to: 'center')

Display draw: square1
Display draw: square2

(*part c: *)

| circle1 circle2 circle3 |
circle1 := Circle new
circle2 := Circle new
circle3 := Circle new

circle1 radius: 90
circle2 radius: 60
circle3 radius: 40

circle1 location: (Point x: 0 y: 0)
circle2 location: (circle1 location adjustPoint: (Point x: circle1 radius + circle2 radius y: 0) to: 'right')
circle3 location: (circle2 location adjustPoint: (Point x: circle2 radius + circle3 radius y: 0) to: 'right')

Display draw: circle1
Display draw: circle2
Display draw: circle3
