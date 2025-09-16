"""#Task1

num = 1

while num < 11:
    print(num)
    num += 1
    
#Task2

for i in range(1, 11):
    print(f"5 x {i} = {i * 5}")
    
#Task3

print("Enter a negative number to stop.")
while True:
    user_input = int(input("Enter a number: "))
    if user_input <= -1:
        break
print(f"You entered a negative number ({user_input})")

#Task4

rows = int(input("Enter your rows: "))

for i in range(1, rows + 1):
    for j in range(rows - i + 1):
        print("* ", end="")    
    print()
"""

"""nums = input("Enter a number: ")
count = 0
i = 0
while i < 1:
    for digit in nums:
        if digit.isdigit():
            count += 1
    i += 1
print("Number of digits:", count)"""

count = int(input("Enter a number: "))
arithmetic = 0
for i in range(count):
    arithmetic += 2
    print(arithmetic)
    if arithmetic == 10:
        break