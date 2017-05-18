# simple dialog to test the functionality of the dialog
# The dialog launcher generates 2 random integers $n1 and $n2
# and displays "$n1 + $n2 is: " and waits for answer.
# on ^U: close dialog
# on ^M: if empty: error: empty message
#        if contains not only numbers: error
#        if contents not eaual to the sum: error
#        if contents equal to the sum: exit dialog