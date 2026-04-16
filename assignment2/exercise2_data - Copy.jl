# w[i,j] = capacity used when assigning job j to machine i
# p[i,j] = profit of assigning job j to machine i
w = [
     2  3  1  6  7
     3  4  3  7  6
     4  7  7  4  6
]
p =[
     1  7  3  8  6
     1  4  4  7  9
     7  2  3  3  7
]
# machine capcities
cap = [35 34 33]
# incompatible job pairs (i.e. job 2 and 4 cannot be assigned to the same machine, the same for job 3 and 4)
K = [(2,4), (3,4)]