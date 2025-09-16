"""list1 = [10, 3, 4, 7, 2, 8, 9, 1]

for n in range(len(list1)-1, 0, -1):
    swapped = False
    for i in range(n):
        if list1[i] > list1[i + 1]:
            list1[i], list1[i + 1] = list1[i + 1], list1[i]
            print(list1)
            swapped = True
    if not swapped:
        break"""
        
"""dictionary = {
    "apple": 3, 
    "banana": 1, 
    "cherry": 2
}
dictionary["date"] = 4

for i, j in dictionary.items():
    j *= 2
    print(f"{i}: {j}")
    
dictionary1 = {"Philippines": "Manila", "Japan": "Tokyo", "Korea": "Seoul"}


list1 = [dictionary, dictionary1]
for i in list1:
    for j in i.items():
        print(f"{j[0]}: {j[1]}")"""
        
"""n = int(input("Enter a number: "))"""

"""for i in range((n)-1, 0, -1):
    for j in range(i):
        j[i] - j[i + 1]
        print(j)"""

import array as arr


"""matrix = [[1, 2, 3], [4, 5, 6], [7, 8, 9]]"""

"""for row in matrix:
    for col in row:
        print(col, end=" ")
    print()"""
    
"""print(matrix[1][2])"""


"""numbers = arr.array("i", [4, 6, 3, 2, 7])
print(sorted(numbers))

data = arr.array("i", [1, 2, 3, 4, 5])
data1 = arr.array("i", [5, 4, 3, 2, 1])

c = arr.array("i")

c = data + data1
print(sorted(c))

print(data[2:4])"""
  
"""arr3D = [
    [ [1, 2], [3, 4] ],
    [ [5, 6], [7, 8] ],
    [ [9, 10], [11, 12] ]    
]

print(arr3D[2][1][1])

for x in arr3D:
    for row in x:
        for col in row:
            print(col, end=" ")
        print()
    print()"""

matrix = [
    [[1, 2], [3, 4]],
    [[5, 6], [7, 8]],
    [[9, 10], [11, 12]]
]

for i in range(len(matrix)):
    for j in range(len(matrix[i])):
        for k in range(len(matrix[i][j])):
            print(f"matrix[{i}][{j}][{k}] = {matrix[i][j][k]}")