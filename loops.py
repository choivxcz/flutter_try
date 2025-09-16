"""num = 0

while num < 51:
    if num % 2 == 0:
        print(num)
    num += 1
print()"""

"""password = "code123"

while True:
    user_input = input("Password: ")
    if user_input == password:
        print("Access granted.")
    else:
        print("Access denied.")"""
        
"""total = 0

for i in range(11):
    total += i
print("Total:", total)"""

"""for i in range(1, 11):
    for j in range(1, 11):
        print(f"{i}*{j}={i*j}", end="\t")
    print()"""

"""for i in range(1, 101):
    if i == 42:
        break
    print(i)"""
    
"""for i in range(1, 21):
    if i % 5 == 0:
        continue
    print(i)"""
    
"""import random

secret_number = random.randint(1, 51)
chances = 5

while True:
    guess = int(input("Enter number: "))
    if guess == secret_number:
        print("yey!")
        break
    elif guess < secret_number:
        chances -= 1
        print("Too low!")
    elif guess > secret_number:
        chances -= 1
        print("Too high!")

    if chances == 0:
        print("Game over!")
        break
print(f"\nMultiplication Table of {secret_number}")
for i in range(1, 6):
    print(f"{secret_number} x {i} = {secret_number * i}")"""
    

for i in range(1, 6):
    for j in range(i):
        print("*", end="")
    print()
print()
for i in range(1, 6):
    for j in range(6 - i):
        print("*", end="")
    print()
print()
for i in range(1, 6): 
    for j in range(1, i + 1):
        print(f"{j}", end="")
    print()
    
for i in range(1, 6):
    for j in range(1, 6):
        print(f"{i*j:2}", end=" ")
    print()