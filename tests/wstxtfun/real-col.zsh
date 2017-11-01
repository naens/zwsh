# 1 2 3 4 5
# a b c d e f g h i j k l m n o p q r s t u v w x y z
wstxtfun-real-col 5 8 "abcdefghijklmnopqrstuvwxyz"
#5


# 1 2 3 4 5
# a b T c d e f g h i j k l m n o p q r s t u v w x y z
# a b c . . . . . d e f g h i j k l m n o p q r s t u v w x y z
# ^ . . . . . . . ^ . . . . . . . ^ . . . . . . . ^ . . . . . . .
# 1 2 3 4 5 6 7 8 9
wstxtfun-real-col 5 8 "abc"$'\t'"defghijklmnopqrstuvwxyz"
#9


# 1 2 3 4 5 6 7 8 9 
# a b c d e f g T h i j k l m n o p q r s t u v w x y z
# a b c d e f g . h i j k l m n o p q r s t u v w x y z
# ^ . . . . . . . ^ . . . . . . . ^ . . . . . . . ^ . . . . . . .
# 1 2 3 4 5 6 7 8 9
wstxtfun-real-col 9 8 "abcdefg"$'\t'"hijklmnopqrstuvwxyz"
#9


# 1 2 3 4 5 6 7 8  9 10 
# a b c d e f g h  T  i  j  k  l  m  n  o  p q r s t u v w x y z
# a b c d e f g h  .  .  .  .  .  .  .  .  i j k l m n o p q r s t u v w x y z
# ^ . . . . . . .  ^  .  .  .  .  .  .  .  ^ . . . . . . . ^ . . . . . . .
# 1 2 3 4 5 6 7 8  9 10 11 12 13 14 15 16 17 
wstxtfun-real-col 10 8 "abcdefgh"$'\t'"ijklmnopqrstuvwxyz"
#17


# 1 2
# T a b c d e f g h i j k l m n o p q r s t u v w x y z
# . . . . . . . . a b c d e f g h i j k l m n o p q r s t u v w x y z
# ^ . . . . . . . ^ . . . . . . . ^ . . . . . . . ^ . . . . . . .
# 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 
wstxtfun-real-col 2 8 $'\t'"abcdefghijklmnopqrstuvwxyz"
#9

wstxtfun-real-col 40 8 "abcdefghijklmnopqrstuvwxyz"
#26

#test string with a newline inside
wstxtfun-real-col 9 8 "123"$'\n'"abc"$'\t'"defghijklmnopqrstuvwxyz"
#9
