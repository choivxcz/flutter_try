"""for i in range(10):
    print(i)

num = -1

password = "code123"

while True:
    user_input = input("Password: ")
    if user_input == password:
        print("Access granted.")
        break
    else:
        print("Access denied.")
        

count = 0

while True:
    print("Count is:", count)
    count += 1

    if count >= 5:
        break

list1 = ["apple", "banana", "cherry"]

for i in list1:
    print(i)


student = {"Name": "Moises Mabaho", "Age": 25, "City": "Kanal"}
for item, name in student.items():
    print(item, name)
    
row = int(input("Enter row: "))

for i in range(1, row + 1 ):
    for j in range(1, row - i + 1):
        print(" ", end= "")
    for j in range(1, i + 1):
        print("* ", end= "")
    print()
    

for i in range(3):
    for j in range(2):
        print(f"i = {i}, j = {j}")

matrix = [[10, 20, 30], [40, 50, 60], [70, 80, 90]]

for row in matrix:
    for element in row:
        print(element, end = " ")
    print()
    
for i in range(10):
    if i == 5:
        i += 2
        continue
    print(i)"""
    
    
print("Task 1")
num = 0
while num < 11:
    print(num)
    num += 1
    
print("Task 2")
for i in range(1, 11):
    print(i * 5)
    
print("Task 3")
while True:
    user_input = int(input("Enter a number: "))
    print("You entered:", user_input)
    if user_input <= -1:
        print("You entered a negative number, loop ended!")
        break

row = 5
for i in range(1, row + 1):
    for j in range(1, row - i + 1):
        print("* ", end="")
    print()